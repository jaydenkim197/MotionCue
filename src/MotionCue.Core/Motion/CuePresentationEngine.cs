namespace MotionCue.Motion;

public sealed class CuePresentationEngine
{
    private const double MaximumOffset = 1;

    public CueFrame CreateFrame(MotionState state, MotionCueMode mode, double simulationIntensity = 1)
    {
        var visible = mode switch
        {
            MotionCueMode.On => true,
            MotionCueMode.Off => false,
            _ => state.AutomaticCuesActive
        };
        var horizontal = Math.Clamp(-state.LateralFiltered * simulationIntensity, -MaximumOffset, MaximumOffset);
        var vertical = Math.Clamp(state.LongitudinalFiltered * simulationIntensity, -MaximumOffset, MaximumOffset);
        var intensity = Math.Clamp(Math.Sqrt((horizontal * horizontal) + (vertical * vertical)), 0, 1);
        return new CueFrame(horizontal, vertical, intensity, visible, state.Timestamp);
    }

    public CueFrame CreateStaticFrame(MotionState state, MotionCueMode mode)
    {
        var visible = mode switch
        {
            MotionCueMode.On => true,
            MotionCueMode.Off => false,
            _ => state.AutomaticCuesActive
        };
        return new CueFrame(0, 0, 0, visible, state.Timestamp);
    }
}
