using System.Windows;
using MotionCue.Windows.AppServices;

namespace MotionCue.Windows.UI;

public partial class OnboardingWindow : Window
{
    private readonly MotionController _controller;

    public OnboardingWindow(MotionController controller)
    {
        _controller = controller;
        InitializeComponent();
    }

    private async void Continue_Click(object sender, RoutedEventArgs e)
    {
        ContinueButton.IsEnabled = false;
        _controller.UpdateSettings(_controller.Settings with { OnboardingCompleted = true });
        Close();
        await _controller.StartAsync(CancellationToken.None);
    }
}

