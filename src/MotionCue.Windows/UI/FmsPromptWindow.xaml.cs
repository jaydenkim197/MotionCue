using System.Windows;
using System.Windows.Controls.Primitives;

namespace MotionCue.Windows.UI;

public partial class FmsPromptWindow : Window
{
    public FmsPromptWindow()
    {
        InitializeComponent();
    }

    public int Score { get; private set; }
    public bool StopRequested { get; private set; }

    private void ScoreSlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        Score = (int)Math.Round(e.NewValue);
        if (ScoreText is not null)
        {
            ScoreText.Text = Score.ToString();
        }
    }

    private void Record_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = true;
        Close();
    }

    private void StopSession_Click(object sender, RoutedEventArgs e)
    {
        StopRequested = true;
        DialogResult = true;
        Close();
    }
}
