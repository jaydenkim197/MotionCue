using System.Windows;
using System.Windows.Media;
using MotionCue.Motion;
using MotionCue.Windows.Settings;

namespace MotionCue.Windows.Overlay;

public sealed class CueSurface : FrameworkElement
{
    private CueFrame _target = new(0, 0, 0, false, DateTimeOffset.UtcNow);
    private double _horizontal;
    private double _vertical;
    private AppSettings _settings = new();
    private System.Windows.Media.Brush _dotBrush = new SolidColorBrush(System.Windows.Media.Color.FromRgb(111, 116, 124));

    public CueSurface()
    {
        IsHitTestVisible = false;
        SnapsToDevicePixels = false;
        UseLayoutRounding = false;
        CompositionTarget.Rendering += OnRendering;
    }

    public void SetFrame(CueFrame frame)
    {
        _target = frame;
        InvalidateVisual();
    }

    public void SetSettings(AppSettings settings)
    {
        _settings = settings;
        try
        {
            _dotBrush = new SolidColorBrush((System.Windows.Media.Color)System.Windows.Media.ColorConverter.ConvertFromString(settings.DotColor));
        }
        catch (FormatException)
        {
            _dotBrush = new SolidColorBrush(System.Windows.Media.Color.FromRgb(111, 116, 124));
        }
        _dotBrush.Freeze();
        InvalidateVisual();
    }

    protected override void OnRender(DrawingContext drawingContext)
    {
        base.OnRender(drawingContext);
        if (!_target.Visible || ActualWidth <= 0 || ActualHeight <= 0)
        {
            return;
        }

        var dotSize = _settings.LargerDots ? 13d : 9d;
        var radius = dotSize / 2;
        var countPerSide = _settings.MoreDots ? 10 : 7;
        var margin = 24d;
        var travel = _settings.Pattern == CuePattern.Dynamic ? 24d : 17d;
        var dx = _horizontal * travel;
        var dy = _vertical * travel;
        var dynamicBoost = _settings.Pattern == CuePattern.Dynamic ? _target.Intensity * 0.22 : 0;

        for (var i = 1; i <= countPerSide; i++)
        {
            var y = i * ActualHeight / (countPerSide + 1);
            DrawDot(drawingContext, margin + dx, y + dy, radius, 0.66 + dynamicBoost);
            DrawDot(drawingContext, ActualWidth - margin + dx, y + dy, radius, 0.66 + dynamicBoost);
        }

        var horizontalCount = Math.Max(4, countPerSide - 2);
        for (var i = 1; i <= horizontalCount; i++)
        {
            var x = i * ActualWidth / (horizontalCount + 1);
            DrawDot(drawingContext, x + dx, margin + dy, radius, 0.58 + dynamicBoost);
            DrawDot(drawingContext, x + dx, ActualHeight - margin + dy, radius, 0.58 + dynamicBoost);
        }
    }

    private void OnRendering(object? sender, EventArgs e)
    {
        if (!_target.Visible)
        {
            return;
        }
        const double interpolation = 0.16;
        _horizontal += (_target.HorizontalOffset - _horizontal) * interpolation;
        _vertical += (_target.VerticalOffset - _vertical) * interpolation;
        InvalidateVisual();
    }

    private void DrawDot(DrawingContext context, double x, double y, double radius, double opacity)
    {
        context.PushOpacity(Math.Clamp(opacity, 0.25, 0.9));
        context.DrawEllipse(_dotBrush, null, new System.Windows.Point(x, y), radius, radius);
        context.Pop();
    }
}
