using MotionCue.Motion;

namespace MotionCue.Windows.Settings;

public sealed record AppSettings
{
    public MotionCueMode Mode { get; init; } = MotionCueMode.Automatic;
    public CuePattern Pattern { get; init; } = CuePattern.Regular;
    public string DotColor { get; init; } = "#6F747C";
    public bool LargerDots { get; init; }
    public bool MoreDots { get; init; }
    public bool StartWithWindows { get; init; }
    public bool OnboardingCompleted { get; init; }
    public bool DeveloperModeEnabled { get; init; }
}

