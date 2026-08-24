using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;
using MotionCue.Motion;
using MotionCue.Windows.Settings;

namespace MotionCue.Windows.Overlay;

public partial class OverlayWindow : Window
{
    private const int GwlExStyle = -20;
    private const int WsExTransparent = 0x00000020;
    private const int WsExToolWindow = 0x00000080;
    private const int WsExNoActivate = 0x08000000;

    public OverlayWindow()
    {
        InitializeComponent();
        Left = 0;
        Top = 0;
        Width = SystemParameters.PrimaryScreenWidth;
        Height = SystemParameters.PrimaryScreenHeight;
        SourceInitialized += OnSourceInitialized;
    }

    public void UpdateFrame(CueFrame frame)
    {
        Surface.SetFrame(frame);
        if (frame.Visible)
        {
            if (!IsVisible)
            {
                Show();
            }
        }
        else if (IsVisible)
        {
            Hide();
        }
    }

    public void UpdateSettings(AppSettings settings) => Surface.SetSettings(settings);

    protected override void OnClosing(System.ComponentModel.CancelEventArgs e)
    {
        e.Cancel = true;
        Hide();
        base.OnClosing(e);
    }

    private void OnSourceInitialized(object? sender, EventArgs e)
    {
        var handle = new WindowInteropHelper(this).Handle;
        var current = GetWindowLongPtr(handle, GwlExStyle).ToInt64();
        SetWindowLongPtr(handle, GwlExStyle, new IntPtr(current | WsExTransparent | WsExToolWindow | WsExNoActivate));
    }

    [DllImport("user32.dll", EntryPoint = "GetWindowLongPtrW")]
    private static extern IntPtr GetWindowLongPtr(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll", EntryPoint = "SetWindowLongPtrW")]
    private static extern IntPtr SetWindowLongPtr(IntPtr hWnd, int nIndex, IntPtr newLong);
}
