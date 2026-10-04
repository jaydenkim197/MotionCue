using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Interop;
using MotionCue.Motion;
using MotionCue.Research;
using MotionCue.Simulation;
using MotionCue.Windows.AppServices;
using MotionCue.Windows.Research;
using MotionCue.Windows.Sensors;

namespace MotionCue.Windows.UI;

public partial class SettingsWindow : Window
{
    private const int WmHotkey = 0x0312;
    private const int EmergencyHotkeyId = 0x4D43;
    private const uint ModControl = 0x0002;
    private const uint ModShift = 0x0004;
    private const uint VirtualKeyF12 = 0x7B;

    private readonly MotionController _controller;
    private readonly ResearchSessionService _research;
    private int _versionClicks;
    private bool _loading = true;
    private HwndSource? _windowSource;
    private FmsPromptWindow? _fmsPrompt;
    private string? _phoneInlineAlert;

    public SettingsWindow(MotionController controller, ResearchSessionService research)
    {
        _controller = controller;
        _research = research;
        InitializeComponent();
        var version = typeof(SettingsWindow).Assembly.GetName().Version;
        VersionText.Text = $"MotionCue {version?.ToString(3) ?? "unknown"} · pilot";
        LoadSettings();
        _controller.SourceStatusChanged += Controller_SourceStatusChanged;
        _controller.StateChanged += Controller_StateChanged;
        _controller.SettingsChanged += Controller_SettingsChanged;
        _research.SessionChanged += Research_SessionChanged;
        _research.FmsDue += Research_FmsDue;
        SourceInitialized += OnSourceInitialized;
        Closed += OnClosed;
        RefreshStatus();
        RefreshResearchUi();
        _loading = false;
    }

    protected override void OnClosing(System.ComponentModel.CancelEventArgs e)
    {
        e.Cancel = true;
        Hide();
        base.OnClosing(e);
    }

    private void LoadSettings()
    {
        var previousLoading = _loading;
        _loading = true;
        var settings = _controller.Settings;
        AutomaticRadio.IsChecked = settings.Mode == MotionCueMode.Automatic;
        OnRadio.IsChecked = settings.Mode == MotionCueMode.On;
        OffRadio.IsChecked = settings.Mode == MotionCueMode.Off;
        RegularRadio.IsChecked = settings.Pattern == CuePattern.Regular;
        DynamicRadio.IsChecked = settings.Pattern == CuePattern.Dynamic;
        LargerDotsCheck.IsChecked = settings.LargerDots;
        MoreDotsCheck.IsChecked = settings.MoreDots;
        StartupCheck.IsChecked = settings.StartWithWindows;
        foreach (ComboBoxItem item in ColorCombo.Items)
        {
            if (string.Equals(item.Tag?.ToString(), settings.DotColor, StringComparison.OrdinalIgnoreCase))
            {
                ColorCombo.SelectedItem = item;
                break;
            }
        }
        ColorCombo.SelectedIndex = Math.Max(0, ColorCombo.SelectedIndex);
        DeveloperPanel.Visibility = settings.DeveloperModeEnabled ? Visibility.Visible : Visibility.Collapsed;
        _loading = previousLoading;
    }

    private void Mode_Checked(object sender, RoutedEventArgs e)
    {
        if (_loading || sender is not System.Windows.Controls.RadioButton { Tag: string tag } || !Enum.TryParse<MotionCueMode>(tag, out var mode))
        {
            return;
        }
        _controller.SetMode(mode);
    }

    private void Pattern_Checked(object sender, RoutedEventArgs e)
    {
        if (_loading || sender is not System.Windows.Controls.RadioButton { Tag: string tag } || !Enum.TryParse<CuePattern>(tag, out var pattern))
        {
            return;
        }
        _controller.UpdateSettings(_controller.Settings with { Pattern = pattern });
    }

    private void ColorCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loading || ColorCombo.SelectedItem is not ComboBoxItem item || item.Tag is not string color)
        {
            return;
        }
        _controller.UpdateSettings(_controller.Settings with { DotColor = color });
    }

    private void Appearance_Click(object sender, RoutedEventArgs e)
    {
        if (_loading)
        {
            return;
        }
        _controller.UpdateSettings(_controller.Settings with
        {
            LargerDots = LargerDotsCheck.IsChecked == true,
            MoreDots = MoreDotsCheck.IsChecked == true
        });
    }

    private void Startup_Click(object sender, RoutedEventArgs e)
    {
        if (!_loading)
        {
            _controller.UpdateSettings(_controller.Settings with { StartWithWindows = StartupCheck.IsChecked == true });
        }
    }

    private void VersionText_MouseLeftButtonUp(object sender, MouseButtonEventArgs e)
    {
        _versionClicks++;
        if (_versionClicks < 5)
        {
            return;
        }
        _versionClicks = 0;
        DeveloperPanel.Visibility = Visibility.Visible;
        if (!_controller.Settings.DeveloperModeEnabled)
        {
            _controller.UpdateSettings(_controller.Settings with { DeveloperModeEnabled = true });
        }
    }

    private async void PhoneSimulation_Click(object sender, RoutedEventArgs e)
    {
        if (sender is System.Windows.Controls.Button { Tag: string tag }
            && Enum.TryParse<PhoneImuSimulationScenario>(tag, out var scenario))
        {
            await _controller.PlayPhoneSimulationAsync(scenario);
        }
    }

    private async void PhoneRefresh_Click(object sender, RoutedEventArgs e)
    {
        var deviceCount = -1;
        ClearPhoneInlineAlert();
        await RunPhoneActionAsync(async () =>
        {
            PhoneRefreshButton.IsEnabled = false;
            var devices = await _controller.DiscoverPhoneSensorsAsync();
            PhoneDeviceCombo.ItemsSource = devices;
            PhoneDeviceCombo.SelectedIndex = devices.Count > 0 ? 0 : -1;
            deviceCount = devices.Count;
        }, "Couldn’t scan for a phone sensor.");
        PhoneRefreshButton.IsEnabled = !_research.IsActive;
        if (deviceCount == 0)
        {
            ShowPhoneInlineAlert("No MotionCue Sensor found. Keep the iPhone app open, then scan again.");
        }
    }

    private async void PhoneConnect_Click(object sender, RoutedEventArgs e)
    {
        if (PhoneDeviceCombo.SelectedItem is not BleSensorCandidate candidate)
        {
            ShowPhoneInlineAlert("Scan first, then select your nearby MotionCue Sensor.");
            return;
        }
        ClearPhoneInlineAlert();
        await RunPhoneActionAsync(() => _controller.ConnectPhoneAsync(candidate), "Couldn’t connect to the phone sensor.");
    }

    private async void PhoneDisconnect_Click(object sender, RoutedEventArgs e) =>
        await RunPhoneActionAsync(_controller.DisconnectPhoneAsync, "Couldn’t disconnect from the phone sensor.");

    private void StartResearch_Click(object sender, RoutedEventArgs e)
    {
        try
        {
            if (ResearchConditionCombo.SelectedItem is not ComboBoxItem { Tag: string conditionTag }
                || !Enum.TryParse<ResearchCondition>(conditionTag, out var condition)
                || FmsIntervalCombo.SelectedItem is not ComboBoxItem { Tag: string intervalTag }
                || !int.TryParse(intervalTag, out var intervalSeconds))
            {
                throw new InvalidOperationException("Select a research condition and FMS interval.");
            }

            if (_controller.SourceStatus.Availability != MotionSourceAvailability.Ready)
            {
                throw new InvalidOperationException("Connect the phone sensor or start virtual SensorFrame replay before the session.");
            }
            if (intervalSeconds >= 60 && !_controller.CanRunProtocolSession)
            {
                throw new InvalidOperationException("Protocol sessions require a live phone IMU connection. Virtual replay is limited to the 10-second QA interval.");
            }

            var config = new ResearchSessionConfig(
                ParticipantCodeText.Text.Trim(),
                SessionIdText.Text.Trim(),
                condition,
                TimeSpan.FromSeconds(intervalSeconds));
            _research.StartSession(config);
            RefreshResearchUi();
        }
        catch (Exception ex) when (ex is ArgumentException or IOException or UnauthorizedAccessException or InvalidOperationException)
        {
            System.Windows.MessageBox.Show(ex.Message, "Cannot start research session", MessageBoxButton.OK, MessageBoxImage.Warning);
        }
    }

    private void StopResearch_Click(object sender, RoutedEventArgs e) =>
        _research.StopSession(emergency: false, "Stopped by researcher");

    private void EmergencyStop_Click(object sender, RoutedEventArgs e) => EmergencyStop("Emergency stop button");

    private void AddMarker_Click(object sender, RoutedEventArgs e)
    {
        try
        {
            _research.AddMarker(MarkerText.Text);
            MarkerText.Clear();
            ResearchStatusText.Text = "Event marker recorded";
        }
        catch (ArgumentException ex)
        {
            System.Windows.MessageBox.Show(ex.Message, "Cannot add marker", MessageBoxButton.OK, MessageBoxImage.Warning);
        }
    }

    private void RecordFms_Click(object sender, RoutedEventArgs e)
    {
        if (ManualFmsCombo.SelectedItem is ComboBoxItem item && int.TryParse(item.Content?.ToString(), out var score))
        {
            _research.RecordFms(score);
            ResearchStatusText.Text = $"FMS {score} recorded at {DateTime.Now:T}";
        }
    }

    private void Controller_SourceStatusChanged(object? sender, MotionSourceStatus e) => RefreshStatus();

    private void Controller_StateChanged(object? sender, MotionState e) => RefreshStatus();

    private void Controller_SettingsChanged(object? sender, Settings.AppSettings e)
    {
        LoadSettings();
        RefreshResearchUi();
    }

    private void Research_SessionChanged(object? sender, EventArgs e) => RefreshResearchUi();

    private void Research_FmsDue(object? sender, EventArgs e)
    {
        if (!_research.IsActive || _fmsPrompt is not null)
        {
            return;
        }

        System.Media.SystemSounds.Asterisk.Play();
        var prompt = new FmsPromptWindow();
        _fmsPrompt = prompt;
        if (IsVisible)
        {
            prompt.Owner = this;
        }
        try
        {
            if (prompt.ShowDialog() == true && _research.IsActive)
            {
                _research.RecordFms(prompt.Score);
                if (prompt.StopRequested)
                {
                    EmergencyStop($"Participant requested stop after FMS {prompt.Score}");
                }
            }
            else if (_research.IsActive)
            {
                _research.AddMarker("FMS prompt dismissed without a rating");
            }
        }
        finally
        {
            _fmsPrompt = null;
        }
    }

    private void RefreshStatus()
    {
        var connected = _controller.SourceStatus.Availability == MotionSourceAvailability.Ready;
        HeaderStatusText.Text = _controller.IsSimulation
            ? "Test signal active"
            : connected
                ? "Phone connected"
                : "Phone not connected";

        StatusText.Text = _controller.IsSimulation
            ? "Virtual phone SensorFrame replay active"
            : connected
                ? $"Phone sensor connected · {_controller.ActiveSourceName}"
                : $"Phone sensor unavailable · {_controller.SourceStatus.Message}";
        PhoneStatusText.Text = _controller.SourceStatus.Message;
        PhoneInlineAlertText.Text = _phoneInlineAlert ?? string.Empty;
        PhoneInlineAlertText.ToolTip = _phoneInlineAlert;
        DiagnosticsText.Text = _controller.BuildDiagnosticsText();
    }

    private void RefreshResearchUi()
    {
        var active = _research.IsActive;
        ParticipantCodeText.IsEnabled = !active;
        SessionIdText.IsEnabled = !active;
        ResearchConditionCombo.IsEnabled = !active;
        FmsIntervalCombo.IsEnabled = !active;
        StartResearchButton.IsEnabled = !active;
        StopResearchButton.IsEnabled = active;
        EmergencyStopButton.IsEnabled = active;
        AddMarkerButton.IsEnabled = active;
        RecordFmsButton.IsEnabled = active;
        MarkerText.IsEnabled = active;
        ManualFmsCombo.IsEnabled = active;
        SimulationControls.IsEnabled = !active;
        PhoneSensorControls.IsEnabled = !active;

        AutomaticRadio.IsEnabled = !active;
        OnRadio.IsEnabled = !active;
        OffRadio.IsEnabled = !active;
        RegularRadio.IsEnabled = !active;
        DynamicRadio.IsEnabled = !active;
        ColorCombo.IsEnabled = !active;
        LargerDotsCheck.IsEnabled = !active;
        MoreDotsCheck.IsEnabled = !active;
        StartupCheck.IsEnabled = !active;

        var config = _research.ActiveConfig;
        if (active && config is not null)
        {
            var elapsed = DateTimeOffset.UtcNow - (_research.StartedAt ?? DateTimeOffset.UtcNow);
            var nextFms = _research.NextFmsAt?.ToLocalTime().ToString("T") ?? "—";
            ResearchStatusText.Text = $"ACTIVE · {config.ParticipantCode} · {config.SessionId} · {config.Condition} · elapsed {elapsed:mm\\:ss} · next FMS {nextFms}";
        }
        else
        {
            ResearchStatusText.Text = "No research session active";
        }

        ResearchOutputText.Text = string.IsNullOrWhiteSpace(_research.OutputPath)
            ? "CSV output will be shown after the session starts."
            : $"CSV: {_research.OutputPath}";
    }

    private void EmergencyStop(string reason)
    {
        _research.StopSession(emergency: true, reason);
        if (_fmsPrompt?.IsVisible == true)
        {
            _fmsPrompt.Close();
        }
        System.Media.SystemSounds.Exclamation.Play();
        RefreshResearchUi();
    }

    private async Task RunPhoneActionAsync(Func<Task> action, string failurePrefix)
    {
        try
        {
            await action();
        }
        catch (Exception ex) when (ex is InvalidOperationException or UnauthorizedAccessException or COMException)
        {
            ShowPhoneInlineAlert($"{failurePrefix} {ex.Message}");
        }
    }

    private void ShowPhoneInlineAlert(string message)
    {
        _phoneInlineAlert = message;
        PhoneInlineAlertText.Text = message;
        PhoneInlineAlertText.ToolTip = message;
    }

    private void ClearPhoneInlineAlert()
    {
        _phoneInlineAlert = null;
        PhoneInlineAlertText.Text = string.Empty;
        PhoneInlineAlertText.ToolTip = null;
    }

    private void OnSourceInitialized(object? sender, EventArgs e)
    {
        var handle = new WindowInteropHelper(this).Handle;
        _windowSource = HwndSource.FromHwnd(handle);
        _windowSource?.AddHook(WindowMessageHook);
        if (!RegisterHotKey(handle, EmergencyHotkeyId, ModControl | ModShift, VirtualKeyF12))
        {
            Trace.TraceWarning("MotionCue could not register the research emergency hotkey.");
        }
    }

    private IntPtr WindowMessageHook(IntPtr hwnd, int message, IntPtr wParam, IntPtr lParam, ref bool handled)
    {
        if (message == WmHotkey && wParam.ToInt32() == EmergencyHotkeyId && _research.IsActive)
        {
            EmergencyStop("Ctrl+Shift+F12 emergency hotkey");
            handled = true;
        }
        return IntPtr.Zero;
    }

    private void OnClosed(object? sender, EventArgs e)
    {
        _controller.SourceStatusChanged -= Controller_SourceStatusChanged;
        _controller.StateChanged -= Controller_StateChanged;
        _controller.SettingsChanged -= Controller_SettingsChanged;
        _research.SessionChanged -= Research_SessionChanged;
        _research.FmsDue -= Research_FmsDue;
        var handle = new WindowInteropHelper(this).Handle;
        if (handle != IntPtr.Zero)
        {
            UnregisterHotKey(handle, EmergencyHotkeyId);
        }
        _windowSource?.RemoveHook(WindowMessageHook);
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint virtualKey);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);
}
