using System.Drawing;
using MotionCue.Motion;
using MotionCue.Windows.AppServices;
using Forms = System.Windows.Forms;

namespace MotionCue.Windows.Platform;

public sealed class TrayIconService : IDisposable
{
    private readonly MotionController _controller;
    private readonly Forms.NotifyIcon _notifyIcon;
    private readonly Forms.ToolStripMenuItem _automaticItem;
    private readonly Forms.ToolStripMenuItem _onItem;
    private readonly Forms.ToolStripMenuItem _offItem;
    private bool _disposed;

    public TrayIconService(MotionController controller)
    {
        _controller = controller;
        _automaticItem = CreateModeItem("Automatic", MotionCueMode.Automatic);
        _onItem = CreateModeItem("On", MotionCueMode.On);
        _offItem = CreateModeItem("Off", MotionCueMode.Off);
        var menu = new Forms.ContextMenuStrip();
        menu.Items.Add(new Forms.ToolStripLabel("Motion Cues") { Font = new Font(Forms.Control.DefaultFont, FontStyle.Bold) });
        menu.Items.Add(new Forms.ToolStripSeparator());
        menu.Items.AddRange([_automaticItem, _onItem, _offItem]);
        menu.Items.Add(new Forms.ToolStripSeparator());
        menu.Items.Add("Settings", null, (_, _) => SettingsRequested?.Invoke(this, EventArgs.Empty));
        menu.Items.Add("Quit", null, (_, _) => QuitRequested?.Invoke(this, EventArgs.Empty));

        _notifyIcon = new Forms.NotifyIcon
        {
            Icon = SystemIcons.Information,
            Text = "MotionCue",
            ContextMenuStrip = menu,
            Visible = true
        };
        _notifyIcon.DoubleClick += (_, _) => SettingsRequested?.Invoke(this, EventArgs.Empty);
        _controller.SettingsChanged += OnSettingsChanged;
        _controller.SourceStatusChanged += OnSourceStatusChanged;
        UpdateChecks();
    }

    public event EventHandler? SettingsRequested;
    public event EventHandler? QuitRequested;

    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }
        _disposed = true;
        _controller.SettingsChanged -= OnSettingsChanged;
        _controller.SourceStatusChanged -= OnSourceStatusChanged;
        _notifyIcon.Visible = false;
        _notifyIcon.Dispose();
    }

    private Forms.ToolStripMenuItem CreateModeItem(string label, MotionCueMode mode)
    {
        var item = new Forms.ToolStripMenuItem(label);
        item.Click += (_, _) => _controller.SetMode(mode);
        return item;
    }

    private void OnSettingsChanged(object? sender, Settings.AppSettings e) => UpdateChecks();

    private void OnSourceStatusChanged(object? sender, MotionSourceStatus status)
    {
        var text = status.Availability == MotionSourceAvailability.Ready
            ? "MotionCue · phone sensor ready"
            : "MotionCue · phone sensor unavailable";
        _notifyIcon.Text = text.Length <= 63 ? text : text[..63];
    }

    private void UpdateChecks()
    {
        _automaticItem.Checked = _controller.Settings.Mode == MotionCueMode.Automatic;
        _onItem.Checked = _controller.Settings.Mode == MotionCueMode.On;
        _offItem.Checked = _controller.Settings.Mode == MotionCueMode.Off;
    }
}
