using System.Windows;
using MotionCue.Windows.AppServices;
using MotionCue.Windows.Overlay;
using MotionCue.Windows.Platform;
using MotionCue.Windows.Research;
using MotionCue.Windows.Sensors;
using MotionCue.Windows.Settings;
using MotionCue.Windows.UI;

namespace MotionCue.Windows;

public partial class App : System.Windows.Application
{
    private MotionController? _controller;
    private OverlayWindow? _overlay;
    private TrayIconService? _tray;
    private SettingsWindow? _settingsWindow;
    private ResearchSessionService? _research;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        DispatcherUnhandledException += OnDispatcherUnhandledException;
        var showSettingsForDiagnostics = e.Args.Any(arg => string.Equals(arg, "--settings", StringComparison.OrdinalIgnoreCase));

        var store = new SettingsStore();
        var settings = store.Load();
        _controller = new MotionController(
            settings,
            store,
            new StartupManager(),
            new WindowsBleSensorClient());
        _overlay = new OverlayWindow();
        _overlay.UpdateSettings(settings);
        _controller.CueFrameChanged += (_, frame) => _overlay.UpdateFrame(frame);
        _controller.SettingsChanged += (_, next) => _overlay.UpdateSettings(next);
        _research = new ResearchSessionService(_controller);

        _tray = new TrayIconService(_controller);
        _tray.SettingsRequested += (_, _) => ShowSettings();
        _tray.QuitRequested += (_, _) => Shutdown();

        if (!settings.OnboardingCompleted)
        {
            new OnboardingWindow(_controller).Show();
        }
        else
        {
            _ = StartControllerAsync();
            if (showSettingsForDiagnostics)
            {
                Dispatcher.BeginInvoke(ShowSettings);
            }
        }
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _research?.Dispose();
        _tray?.Dispose();
        if (_controller is not null)
        {
            _controller.DisposeAsync().AsTask().GetAwaiter().GetResult();
        }
        base.OnExit(e);
    }

    private async Task StartControllerAsync()
    {
        if (_controller is not null)
        {
            await _controller.StartAsync(CancellationToken.None);
        }
    }

    private void ShowSettings()
    {
        if (_controller is null || _research is null)
        {
            return;
        }
        _settingsWindow ??= new SettingsWindow(_controller, _research);
        if (!_settingsWindow.IsVisible)
        {
            _settingsWindow.Show();
        }
        _settingsWindow.Activate();
    }

    private void OnDispatcherUnhandledException(object sender, System.Windows.Threading.DispatcherUnhandledExceptionEventArgs e)
    {
        System.Windows.MessageBox.Show(
            $"MotionCue encountered an unexpected error and will close.\n\n{e.Exception.Message}",
            "MotionCue",
            MessageBoxButton.OK,
            MessageBoxImage.Error);
        e.Handled = true;
        Shutdown(1);
    }
}
