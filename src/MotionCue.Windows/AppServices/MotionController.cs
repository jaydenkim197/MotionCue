using System.Diagnostics;
using MotionCue.Motion;
using MotionCue.Sensors;
using MotionCue.Simulation;
using MotionCue.Windows.Sensors;
using MotionCue.Windows.Settings;

namespace MotionCue.Windows.AppServices;

public sealed class MotionController : IAsyncDisposable
{
    private static readonly TimeSpan NeutralAfter = TimeSpan.FromMilliseconds(250);
    private static readonly TimeSpan DisconnectedAfter = TimeSpan.FromSeconds(1);
    private readonly object _gate = new();
    private readonly SynchronizationContext _uiContext;
    private readonly WindowsBleSensorClient _bleClient;
    private readonly PhoneImuEstimator _phoneEstimator = new();
    private readonly CuePresentationEngine _presentation = new();
    private readonly SettingsStore _settingsStore;
    private readonly Platform.StartupManager _startupManager;
    private readonly System.Threading.Timer _lossTimer;
    private CancellationTokenSource? _simulationCancellation;
    private DateTimeOffset _sourceActivatedAt = DateTimeOffset.MinValue;
    private DateTimeOffset _lastFrameAt = DateTimeOffset.MinValue;
    private SensorLinkState _linkState = SensorLinkState.Waiting;
    private AppSettings? _temporarySettingsOriginal;
    private bool _staticResearchCue;
    private bool _sourceActive;
    private bool _isSimulation;
    private bool _disposed;

    public MotionController(AppSettings settings, SettingsStore settingsStore, Platform.StartupManager startupManager, WindowsBleSensorClient bleClient)
    {
        Settings = settings;
        _settingsStore = settingsStore;
        _startupManager = startupManager;
        _bleClient = bleClient;
        _uiContext = SynchronizationContext.Current ?? new SynchronizationContext();
        CurrentState = _phoneEstimator.State;
        SourceStatus = new MotionSourceStatus(MotionSourceAvailability.Stopped, MotionSourceKind.PhoneImu,
            "Connect a phone sensor or run virtual SensorFrame replay", DateTimeOffset.UtcNow);
        CurrentFrame = _presentation.CreateFrame(CurrentState, MotionCueMode.Off);
        _bleClient.StatusChanged += OnBleStatusChanged;
        _bleClient.FrameReceived += OnBleFrameReceived;
        _bleClient.FrameRejected += OnBleFrameRejected;
        _lossTimer = new System.Threading.Timer(OnLossTimer, null, Timeout.InfiniteTimeSpan, Timeout.InfiniteTimeSpan);
    }

    public AppSettings Settings { get; private set; }
    public MotionState CurrentState { get; private set; }
    public MotionSourceStatus SourceStatus { get; private set; }
    public CueFrame CurrentFrame { get; private set; }
    public bool IsSimulation => _isSimulation;
    public bool IsPhoneSensor => _sourceActive && !_isSimulation;
    public bool CanRunProtocolSession => IsPhoneSensor && SourceStatus.Availability == MotionSourceAvailability.Ready;
    public bool HasTemporarySettings => _temporarySettingsOriginal is not null;
    public string ActiveSourceName => _isSimulation
        ? "Virtual SensorFrame replay"
        : _bleClient.Status.DeviceName ?? (_sourceActive ? "Phone IMU over BLE" : "None");

    public event EventHandler<MotionState>? StateChanged;
    public event EventHandler<MotionSourceStatus>? SourceStatusChanged;
    public event EventHandler<CueFrame>? CueFrameChanged;
    public event EventHandler<AppSettings>? SettingsChanged;

    public Task StartAsync(CancellationToken cancellationToken)
    {
        ThrowIfDisposed();
        cancellationToken.ThrowIfCancellationRequested();
        _lossTimer.Change(TimeSpan.FromMilliseconds(100), TimeSpan.FromMilliseconds(100));
        PublishState(CurrentState);
        PublishSourceStatus(SourceStatus);
        return Task.CompletedTask;
    }

    public async Task<IReadOnlyList<BleSensorCandidate>> DiscoverPhoneSensorsAsync(CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        CancelSimulation();
        _isSimulation = false;
        _sourceActive = false;
        await _bleClient.DisconnectAsync();
        ResetPhoneInput(DateTimeOffset.UtcNow);
        SetSourceStatus(MotionSourceAvailability.Discovering, MotionSourceKind.PhoneImu, "Scanning for nearby MotionCue sensors and paired BLE devices");
        try
        {
            var devices = await WindowsBleSensorClient.DiscoverAsync(cancellationToken);
            SetSourceStatus(MotionSourceAvailability.Stopped, MotionSourceKind.PhoneImu,
                devices.Count == 0 ? "No nearby or paired BLE devices found" : $"Found {devices.Count} BLE device(s)");
            return devices;
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            SetSourceStatus(MotionSourceAvailability.Faulted, MotionSourceKind.PhoneImu, $"BLE discovery failed: {ex.Message}");
            throw;
        }
    }

    public async Task ConnectPhoneAsync(BleSensorCandidate candidate, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(candidate);
        CancelSimulation();
        _isSimulation = false;
        _sourceActive = true;
        ResetPhoneInput(DateTimeOffset.UtcNow);
        SetSourceStatus(MotionSourceAvailability.Connecting, MotionSourceKind.PhoneImu, $"Connecting to {candidate.Name}");
        try
        {
            await _bleClient.ConnectAsync(candidate, cancellationToken);
        }
        catch
        {
            _sourceActive = false;
            throw;
        }
    }

    public async Task DisconnectPhoneAsync()
    {
        ThrowIfDisposed();
        CancelSimulation();
        _sourceActive = false;
        _isSimulation = false;
        await _bleClient.DisconnectAsync();
        ResetPhoneInput(DateTimeOffset.UtcNow);
        SetSourceStatus(MotionSourceAvailability.Stopped, MotionSourceKind.PhoneImu, "Phone sensor disconnected");
    }

    public async Task PlayPhoneSimulationAsync(PhoneImuSimulationScenario scenario, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        CancelSimulation();
        await _bleClient.DisconnectAsync();
        _simulationCancellation = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        _isSimulation = true;
        _sourceActive = true;
        ResetPhoneInput(DateTimeOffset.UtcNow);
        SetSourceStatus(MotionSourceAvailability.Ready, MotionSourceKind.Simulation, $"Virtual SensorFrame: {scenario}");
        _ = PlayPhoneSimulationCoreAsync(scenario, _simulationCancellation.Token);
    }

    public void SetMode(MotionCueMode mode)
    {
        if (!HasTemporarySettings)
        {
            UpdateSettings(Settings with { Mode = mode });
        }
    }

    public void UpdateSettings(AppSettings settings)
    {
        ThrowIfDisposed();
        if (HasTemporarySettings)
        {
            return;
        }
        Settings = settings;
        _settingsStore.Save(Settings);
        _startupManager.SetEnabled(Settings.StartWithWindows);
        PublishOnUi(() =>
        {
            SettingsChanged?.Invoke(this, Settings);
            PublishFrame();
        });
    }

    public void BeginTemporarySettings(AppSettings settings, bool staticResearchCue = false)
    {
        ThrowIfDisposed();
        if (HasTemporarySettings)
        {
            throw new InvalidOperationException("Temporary research settings are already active.");
        }
        _temporarySettingsOriginal = Settings;
        _staticResearchCue = staticResearchCue;
        Settings = settings;
        PublishSettingsAndFrame();
    }

    public void EndTemporarySettings(bool forceOff)
    {
        if (_temporarySettingsOriginal is null)
        {
            return;
        }
        var restored = _temporarySettingsOriginal;
        _temporarySettingsOriginal = null;
        _staticResearchCue = false;
        Settings = forceOff ? restored with { Mode = MotionCueMode.Off } : restored;
        if (forceOff)
        {
            _settingsStore.Save(Settings);
        }
        PublishSettingsAndFrame();
    }

    public string BuildDiagnosticsText()
    {
        var state = CurrentState;
        var tuning = _phoneEstimator.Tuning;
        var timing = _bleClient.TimingSnapshot;
        return string.Join(Environment.NewLine,
            $"Source: {ActiveSourceName}",
            $"Availability: {SourceStatus.Availability}",
            $"Source kind: {SourceStatus.SourceKind}",
            $"BLE state: {_bleClient.Status.State}",
            $"BLE PDU: {(_bleClient.Status.MaxPduSize is null ? "—" : $"{_bleClient.Status.MaxPduSize} bytes")}",
            $"BLE accepted / missing / rejected: {timing.AcceptedFrames} / {timing.MissingFrames} / {timing.RejectedFrames}",
            $"BLE sequence gaps: {timing.SequenceGapRate:P2} (includes sender-side drops)",
            $"BLE interval p50 / p95: {timing.MedianIntervalMilliseconds:F1} / {timing.P95IntervalMilliseconds:F1} ms",
            $"BLE interval max / jitter SD: {timing.MaximumIntervalMilliseconds:F1} / {timing.IntervalStandardDeviationMilliseconds:F1} ms",
            $"BLE timing window: {timing.WindowIntervals} intervals (max 1500; not one-way latency)",
            $"Link watchdog: {_linkState}",
            $"Sample timestamp: {state.Timestamp:O}",
            $"Sample interval: {(state.SampleInterval is null ? "—" : $"{state.SampleInterval.Value.TotalMilliseconds:F0} ms")}",
            $"Longitudinal raw / filtered: {state.LongitudinalRaw:F3} / {state.LongitudinalFiltered:F3}",
            $"Lateral raw / filtered: {state.LateralRaw:F3} / {state.LateralFiltered:F3}",
            $"Activation confidence: {state.ActivationConfidence:P0}",
            $"Automatic active: {state.AutomaticCuesActive}",
            $"Cue visible: {CurrentFrame.Visible}",
            $"State: {state.SampleStatus}",
            string.Empty,
            "Provisional Phone IMU tuning",
            $"Dead zones longitudinal / lateral: {tuning.LongitudinalDeadZoneMetersPerSecondSquared:F2} / {tuning.LateralDeadZoneMetersPerSecondSquared:F2} m/s²",
            $"Normalization maxima longitudinal / lateral: {tuning.MaximumLongitudinalAccelerationMetersPerSecondSquared:F1} / {tuning.MaximumLateralAccelerationMetersPerSecondSquared:F1} m/s²",
            $"Motion smoothing time constant: {tuning.MotionSmoothingTimeConstantSeconds:F2} s",
            $"Watchdog neutral / disconnected: {NeutralAfter.TotalMilliseconds:F0} / {DisconnectedAfter.TotalMilliseconds:F0} ms",
            "These constants are engineering defaults, not validated effect parameters.");
    }

    public async ValueTask DisposeAsync()
    {
        if (_disposed)
        {
            return;
        }
        _disposed = true;
        _lossTimer.Dispose();
        CancelSimulation();
        _bleClient.StatusChanged -= OnBleStatusChanged;
        _bleClient.FrameReceived -= OnBleFrameReceived;
        _bleClient.FrameRejected -= OnBleFrameRejected;
        await _bleClient.DisposeAsync();
    }

    private async Task PlayPhoneSimulationCoreAsync(PhoneImuSimulationScenario scenario, CancellationToken cancellationToken)
    {
        try
        {
            foreach (var frame in PhoneImuSimulationScenarios.Create(scenario))
            {
                cancellationToken.ThrowIfCancellationRequested();
                if (frame is { } sensorFrame)
                {
                    ProcessPhoneFrame(sensorFrame, DateTimeOffset.UtcNow);
                }
                await Task.Delay(TimeSpan.FromMilliseconds(40), cancellationToken);
            }
        }
        catch (OperationCanceledException)
        {
        }
        catch (Exception ex)
        {
            Trace.TraceError("MotionCue Phone IMU replay failed: {0}", ex);
            SetSourceStatus(MotionSourceAvailability.Faulted, MotionSourceKind.Simulation, ex.Message);
        }
    }

    private void OnBleFrameReceived(object? sender, BleSensorFrameEventArgs e) => ProcessPhoneFrame(e.Frame, e.ReceivedAt);

    private void ProcessPhoneFrame(SensorFrame frame, DateTimeOffset receivedAt)
    {
        MotionState state;
        lock (_gate)
        {
            state = _phoneEstimator.Process(frame, receivedAt);
            if (state.SampleAccepted)
            {
                _lastFrameAt = receivedAt;
                _linkState = SensorLinkState.Streaming;
            }
            CurrentState = state;
        }
        if (state.SampleAccepted
            && SourceStatus.Availability is MotionSourceAvailability.Disconnected or MotionSourceAvailability.Faulted)
        {
            SetSourceStatus(MotionSourceAvailability.Ready, _isSimulation ? MotionSourceKind.Simulation : MotionSourceKind.PhoneImu, "SensorFrame stream restored");
        }
        PublishState(state);
    }

    private void OnBleFrameRejected(object? sender, BleSensorDecodeErrorEventArgs e) =>
        SetSourceStatus(MotionSourceAvailability.Ready, MotionSourceKind.PhoneImu, $"Rejected SensorFrame: {e.Error}; waiting for the next valid frame");

    private void OnBleStatusChanged(object? sender, BleSensorStatus status)
    {
        if (_isSimulation)
        {
            return;
        }
        var availability = status.State switch
        {
            BleSensorClientState.Discovering => MotionSourceAvailability.Discovering,
            BleSensorClientState.Connecting => MotionSourceAvailability.Connecting,
            BleSensorClientState.Subscribed => MotionSourceAvailability.Ready,
            BleSensorClientState.Disconnected => MotionSourceAvailability.Disconnected,
            BleSensorClientState.Faulted => MotionSourceAvailability.Faulted,
            _ => MotionSourceAvailability.Stopped
        };
        _sourceActive = status.State is BleSensorClientState.Connecting or BleSensorClientState.Subscribed;
        if (status.State == BleSensorClientState.Subscribed)
        {
            _sourceActivatedAt = DateTimeOffset.UtcNow;
        }
        if (availability is MotionSourceAvailability.Disconnected or MotionSourceAvailability.Faulted)
        {
            NeutralizePhone(disconnected: true, status.Message);
        }
        SetSourceStatus(availability, MotionSourceKind.PhoneImu, status.Message);
    }

    private void OnLossTimer(object? state)
    {
        if (_disposed || !_sourceActive)
        {
            return;
        }
        var now = DateTimeOffset.UtcNow;
        var reference = _lastFrameAt == DateTimeOffset.MinValue ? _sourceActivatedAt : _lastFrameAt;
        if (reference == DateTimeOffset.MinValue)
        {
            return;
        }
        var age = now - reference;
        if (age >= DisconnectedAfter && _linkState != SensorLinkState.Disconnected)
        {
            _linkState = SensorLinkState.Disconnected;
            NeutralizePhone(disconnected: true, "SensorFrame stream timed out");
            SetSourceStatus(MotionSourceAvailability.Disconnected, _isSimulation ? MotionSourceKind.Simulation : MotionSourceKind.PhoneImu, "No SensorFrame received for 1 second");
        }
        else if (age >= NeutralAfter && _linkState == SensorLinkState.Streaming)
        {
            _linkState = SensorLinkState.Neutralizing;
            NeutralizePhone(disconnected: false, "SensorFrame stream overdue");
        }
    }

    private void NeutralizePhone(bool disconnected, string status)
    {
        MotionState state;
        lock (_gate)
        {
            state = _phoneEstimator.Neutralize(DateTimeOffset.UtcNow, disconnected) with { SampleStatus = status };
            CurrentState = state;
        }
        PublishState(state);
    }

    private void ResetPhoneInput(DateTimeOffset now)
    {
        lock (_gate)
        {
            _phoneEstimator.Reset(now);
            CurrentState = _phoneEstimator.State;
            _sourceActivatedAt = now;
            _lastFrameAt = DateTimeOffset.MinValue;
            _linkState = SensorLinkState.Waiting;
        }
        PublishState(CurrentState);
    }

    private void CancelSimulation()
    {
        _simulationCancellation?.Cancel();
        _simulationCancellation?.Dispose();
        _simulationCancellation = null;
    }

    private void SetSourceStatus(MotionSourceAvailability availability, MotionSourceKind kind, string message)
    {
        SourceStatus = new MotionSourceStatus(availability, kind, message, DateTimeOffset.UtcNow);
        PublishSourceStatus(SourceStatus);
        PublishOnUi(PublishFrame);
    }

    private void PublishState(MotionState state) => PublishOnUi(() =>
    {
        StateChanged?.Invoke(this, state);
        PublishFrame();
    });

    private void PublishSourceStatus(MotionSourceStatus status) => PublishOnUi(() => SourceStatusChanged?.Invoke(this, status));

    private void PublishFrame()
    {
        var effectiveMode = SourceStatus.Availability == MotionSourceAvailability.Ready ? Settings.Mode : MotionCueMode.Off;
        CurrentFrame = _staticResearchCue && effectiveMode == MotionCueMode.On
            ? new CueFrame(0, 0, 0, true, CurrentState.Timestamp)
            : _presentation.CreateFrame(CurrentState, effectiveMode);
        CueFrameChanged?.Invoke(this, CurrentFrame);
    }

    private void PublishSettingsAndFrame() => PublishOnUi(() =>
    {
        SettingsChanged?.Invoke(this, Settings);
        PublishFrame();
    });

    private void PublishOnUi(Action action) => _uiContext.Post(_ => action(), null);
    private void ThrowIfDisposed() => ObjectDisposedException.ThrowIf(_disposed, this);
}
