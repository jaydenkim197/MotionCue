using System.Collections.Concurrent;
using MotionCue.Sensors;
using Windows.Devices.Bluetooth;
using Windows.Devices.Bluetooth.Advertisement;
using Windows.Devices.Bluetooth.GenericAttributeProfile;
using Windows.Devices.Enumeration;
using Windows.Storage.Streams;

namespace MotionCue.Windows.Sensors;

public enum BleSensorClientState
{
    Stopped,
    Discovering,
    Connecting,
    Subscribed,
    Disconnected,
    Faulted
}

public sealed record BleSensorCandidate(string Id, string Name, bool IsPaired, ulong? BluetoothAddress = null);

public sealed record BleSensorStatus(
    BleSensorClientState State,
    string Message,
    string? DeviceName,
    ushort? MaxPduSize,
    DateTimeOffset Timestamp);

public sealed class BleSensorFrameEventArgs(
    SensorFrame frame,
    SensorStreamObservation observation,
    DateTimeOffset receivedAt) : EventArgs
{
    public SensorFrame Frame { get; } = frame;
    public SensorStreamObservation Observation { get; } = observation;
    public DateTimeOffset ReceivedAt { get; } = receivedAt;
}

public sealed class BleSensorDecodeErrorEventArgs(
    SensorFrameDecodeError error,
    int receivedLength,
    DateTimeOffset receivedAt) : EventArgs
{
    public SensorFrameDecodeError Error { get; } = error;
    public int ReceivedLength { get; } = receivedLength;
    public DateTimeOffset ReceivedAt { get; } = receivedAt;
}

public sealed class WindowsBleSensorClient : IAsyncDisposable
{
    private readonly SemaphoreSlim _lifecycleGate = new(1, 1);
    private readonly object _frameGate = new();
    private readonly SensorSequenceTracker _sequenceTracker = new();
    private readonly SensorLinkWatchdog _watchdog = new();
    private BluetoothLEDevice? _device;
    private GattSession? _session;
    private GattDeviceService? _service;
    private GattCharacteristic? _frameCharacteristic;
    private bool _disposed;

    public BleSensorStatus Status { get; private set; } = new(
        BleSensorClientState.Stopped,
        "Phone sensor BLE client is stopped",
        null,
        null,
        DateTimeOffset.UtcNow);

    public event EventHandler<BleSensorStatus>? StatusChanged;
    public event EventHandler<BleSensorFrameEventArgs>? FrameReceived;
    public event EventHandler<BleSensorDecodeErrorEventArgs>? FrameRejected;

    public static async Task<IReadOnlyList<BleSensorCandidate>> DiscoverAsync(
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var nearby = new ConcurrentDictionary<ulong, BleSensorCandidate>();
        Exception? scanFailure = null;
        var watcher = new BluetoothLEAdvertisementWatcher { ScanningMode = BluetoothLEScanningMode.Active };
        watcher.AdvertisementFilter.Advertisement.ServiceUuids.Add(SensorGattProfile.ServiceUuid);
        void OnAdvertisementReceived(BluetoothLEAdvertisementWatcher sender, BluetoothLEAdvertisementReceivedEventArgs args)
        {
            var name = string.IsNullOrWhiteSpace(args.Advertisement.LocalName)
                ? $"MotionCue sensor {args.BluetoothAddress:X12}"
                : args.Advertisement.LocalName;
            nearby[args.BluetoothAddress] = new BleSensorCandidate(
                $"ble-address:{args.BluetoothAddress:X12}", name, false, args.BluetoothAddress);
        }

        watcher.Received += OnAdvertisementReceived;
        try
        {
            watcher.Start();
            await Task.Delay(TimeSpan.FromSeconds(4), cancellationToken);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            scanFailure = ex;
        }
        finally
        {
            if (watcher.Status == BluetoothLEAdvertisementWatcherStatus.Started)
            {
                watcher.Stop();
            }
            watcher.Received -= OnAdvertisementReceived;
        }

        BleSensorCandidate[] paired;
        Exception? pairedFailure = null;
        try
        {
            var selector = BluetoothLEDevice.GetDeviceSelectorFromPairingState(true);
            var devices = await DeviceInformation.FindAllAsync(selector);
            cancellationToken.ThrowIfCancellationRequested();
            paired = devices
                .Where(device => device.Pairing.IsPaired)
                .Select(device => new BleSensorCandidate(
                    device.Id,
                    string.IsNullOrWhiteSpace(device.Name) ? "Unnamed BLE device" : device.Name,
                    device.Pairing.IsPaired))
                .ToArray();
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            paired = [];
            pairedFailure = ex;
        }

        if (nearby.IsEmpty && paired.Length == 0 && scanFailure is not null)
        {
            throw new InvalidOperationException(
                $"Nearby BLE scan failed ({Describe(scanFailure)}). Paired-device lookup: {Describe(pairedFailure)}.",
                scanFailure);
        }

        return paired
            .Concat(nearby.Values)
            .GroupBy(candidate => candidate.Id, StringComparer.OrdinalIgnoreCase)
            .Select(group => group.First())
            .OrderBy(candidate => candidate.Name, StringComparer.OrdinalIgnoreCase)
            .ToArray();
    }

    private static string Describe(Exception? exception)
    {
        if (exception is null)
        {
            return "available";
        }
        if (exception.HResult == unchecked((int)0x800710DF))
        {
            return "Bluetooth radio is not ready; verify that Bluetooth is turned on (HRESULT 0x800710DF)";
        }
        return $"{exception.GetType().Name}, HRESULT 0x{exception.HResult:X8}{(string.IsNullOrWhiteSpace(exception.Message) ? string.Empty : $": {exception.Message}")}";
    }

    public async Task ConnectAsync(BleSensorCandidate candidate, CancellationToken cancellationToken = default)
    {
        ObjectDisposedException.ThrowIf(_disposed, this);
        ArgumentNullException.ThrowIfNull(candidate);
        await _lifecycleGate.WaitAsync(cancellationToken);
        try
        {
            await DisconnectCoreAsync();
            SetStatus(BleSensorClientState.Connecting, "Connecting to phone sensor", null, null);
            cancellationToken.ThrowIfCancellationRequested();

            _device = candidate.BluetoothAddress is { } address
                ? await BluetoothLEDevice.FromBluetoothAddressAsync(address)
                : await BluetoothLEDevice.FromIdAsync(candidate.Id);
            if (_device is null)
            {
                throw new InvalidOperationException("Windows could not open the selected BLE device.");
            }
            _device.ConnectionStatusChanged += OnConnectionStatusChanged;

            _session = await GattSession.FromDeviceIdAsync(_device.BluetoothDeviceId)
                ?? throw new InvalidOperationException("Windows could not create a GATT session.");
            _session.MaintainConnection = true;

            var services = await _device.GetGattServicesForUuidAsync(
                SensorGattProfile.ServiceUuid,
                BluetoothCacheMode.Uncached);
            cancellationToken.ThrowIfCancellationRequested();
            if (services.Status != GattCommunicationStatus.Success || services.Services.Count != 1)
            {
                throw new InvalidOperationException(
                    $"MotionCue sensor service was not found. GATT status: {services.Status}.");
            }
            _service = services.Services[0];

            var characteristics = await _service.GetCharacteristicsForUuidAsync(
                SensorGattProfile.SensorFrameCharacteristicUuid,
                BluetoothCacheMode.Uncached);
            cancellationToken.ThrowIfCancellationRequested();
            if (characteristics.Status != GattCommunicationStatus.Success || characteristics.Characteristics.Count != 1)
            {
                throw new InvalidOperationException(
                    $"MotionCue SensorFrame characteristic was not found. GATT status: {characteristics.Status}.");
            }

            _frameCharacteristic = characteristics.Characteristics[0];
            if (!_frameCharacteristic.CharacteristicProperties.HasFlag(GattCharacteristicProperties.Notify))
            {
                throw new InvalidOperationException("SensorFrame characteristic does not support BLE notifications.");
            }

            await EnsureFrameCapacityAsync(_session, cancellationToken);
            _frameCharacteristic.ValueChanged += OnFrameValueChanged;
            var subscription = await _frameCharacteristic.WriteClientCharacteristicConfigurationDescriptorAsync(
                GattClientCharacteristicConfigurationDescriptorValue.Notify);
            if (subscription != GattCommunicationStatus.Success)
            {
                _frameCharacteristic.ValueChanged -= OnFrameValueChanged;
                throw new InvalidOperationException($"SensorFrame notification subscription failed: {subscription}.");
            }

            lock (_frameGate)
            {
                _sequenceTracker.Reset();
                _watchdog.Reset();
            }
            SetStatus(
                BleSensorClientState.Subscribed,
                "Subscribed to SensorFrame notifications",
                _device.Name,
                _session.MaxPduSize);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            SetStatus(BleSensorClientState.Faulted, ex.Message, _device?.Name, _session?.MaxPduSize);
            await DisconnectCoreAsync(preserveFaultStatus: true);
            throw;
        }
        finally
        {
            _lifecycleGate.Release();
        }
    }

    public SensorLinkState EvaluateLinkState(DateTimeOffset now)
    {
        lock (_frameGate)
        {
            return _watchdog.Evaluate(now);
        }
    }

    public async Task DisconnectAsync()
    {
        await _lifecycleGate.WaitAsync();
        try
        {
            await DisconnectCoreAsync();
        }
        finally
        {
            _lifecycleGate.Release();
        }
    }

    public async ValueTask DisposeAsync()
    {
        if (_disposed)
        {
            return;
        }
        _disposed = true;
        await DisconnectAsync();
        _lifecycleGate.Dispose();
    }

    private static async Task EnsureFrameCapacityAsync(GattSession session, CancellationToken cancellationToken)
    {
        const int AttNotificationHeaderBytes = 3;
        var requiredPdu = SensorFrameCodec.EncodedLength + AttNotificationHeaderBytes;
        if (session.MaxPduSize >= requiredPdu)
        {
            return;
        }

        var capacityChanged = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        void OnMaxPduSizeChanged(GattSession sender, object args)
        {
            if (sender.MaxPduSize >= requiredPdu)
            {
                capacityChanged.TrySetResult();
            }
        }

        session.MaxPduSizeChanged += OnMaxPduSizeChanged;
        try
        {
            await capacityChanged.Task.WaitAsync(TimeSpan.FromSeconds(2), cancellationToken);
        }
        catch (TimeoutException)
        {
            throw new InvalidOperationException(
                $"Negotiated GATT PDU {session.MaxPduSize} bytes cannot carry the {SensorFrameCodec.EncodedLength}-byte SensorFrame v1 notification.");
        }
        finally
        {
            session.MaxPduSizeChanged -= OnMaxPduSizeChanged;
        }
    }

    private void OnFrameValueChanged(GattCharacteristic sender, GattValueChangedEventArgs args)
    {
        var receivedAt = DateTimeOffset.UtcNow;
        using var reader = DataReader.FromBuffer(args.CharacteristicValue);
        var bytes = new byte[reader.UnconsumedBufferLength];
        reader.ReadBytes(bytes);

        if (!SensorFrameCodec.TryDecode(bytes, out var frame, out var error))
        {
            FrameRejected?.Invoke(this, new BleSensorDecodeErrorEventArgs(error, bytes.Length, receivedAt));
            return;
        }

        SensorStreamObservation observation;
        lock (_frameGate)
        {
            if (frame.Flags.HasFlag(SensorFrameFlags.ClockReset))
            {
                _sequenceTracker.Reset();
            }
            observation = _sequenceTracker.Observe(frame.Sequence);
            if (observation.Disposition is SensorFrameDisposition.Accepted or SensorFrameDisposition.AcceptedWithGap)
            {
                _watchdog.Observe(receivedAt);
            }
        }

        if (observation.Disposition is SensorFrameDisposition.Accepted or SensorFrameDisposition.AcceptedWithGap)
        {
            FrameReceived?.Invoke(this, new BleSensorFrameEventArgs(frame, observation, receivedAt));
        }
    }

    private void OnConnectionStatusChanged(BluetoothLEDevice sender, object args)
    {
        if (sender.ConnectionStatus == BluetoothConnectionStatus.Disconnected
            && Status.State == BleSensorClientState.Subscribed)
        {
            SetStatus(
                BleSensorClientState.Disconnected,
                "Phone sensor BLE connection was lost",
                sender.Name,
                _session?.MaxPduSize);
        }
    }

    private async Task DisconnectCoreAsync(bool preserveFaultStatus = false)
    {
        if (_frameCharacteristic is not null)
        {
            _frameCharacteristic.ValueChanged -= OnFrameValueChanged;
            try
            {
                await _frameCharacteristic.WriteClientCharacteristicConfigurationDescriptorAsync(
                    GattClientCharacteristicConfigurationDescriptorValue.None);
            }
            catch
            {
                // The remote device may already be gone; local references are still released below.
            }
            _frameCharacteristic = null;
        }
        _service?.Dispose();
        _service = null;
        _session?.Dispose();
        _session = null;
        if (_device is not null)
        {
            _device.ConnectionStatusChanged -= OnConnectionStatusChanged;
            _device.Dispose();
            _device = null;
        }
        lock (_frameGate)
        {
            _sequenceTracker.Reset();
            _watchdog.Reset();
        }
        if (!preserveFaultStatus)
        {
            SetStatus(BleSensorClientState.Stopped, "Phone sensor BLE client is stopped", null, null);
        }
    }

    private void SetStatus(BleSensorClientState state, string message, string? deviceName, ushort? maxPduSize)
    {
        Status = new BleSensorStatus(state, message, deviceName, maxPduSize, DateTimeOffset.UtcNow);
        StatusChanged?.Invoke(this, Status);
    }
}
