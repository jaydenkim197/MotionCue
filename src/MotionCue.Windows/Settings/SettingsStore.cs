using System.Text.Json;
using System.IO;
using System.Diagnostics;

namespace MotionCue.Windows.Settings;

public sealed class SettingsStore
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true,
        PropertyNameCaseInsensitive = true
    };

    private readonly string _directory;
    private readonly string _path;

    public SettingsStore()
    {
        _directory = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "MotionCue");
        _path = Path.Combine(_directory, "settings.json");
    }

    public AppSettings Load()
    {
        try
        {
            if (!File.Exists(_path))
            {
                return new AppSettings();
            }

            return JsonSerializer.Deserialize<AppSettings>(File.ReadAllText(_path), JsonOptions) ?? new AppSettings();
        }
        catch (JsonException)
        {
            QuarantineCorruptedSettings();
            return new AppSettings();
        }
        catch (IOException ex)
        {
            Trace.TraceWarning("MotionCue could not read settings: {0}", ex.Message);
            return new AppSettings();
        }
        catch (UnauthorizedAccessException ex)
        {
            Trace.TraceWarning("MotionCue does not have access to settings: {0}", ex.Message);
            return new AppSettings();
        }
    }

    public void Save(AppSettings settings)
    {
        Directory.CreateDirectory(_directory);
        var temporaryPath = _path + ".tmp";
        File.WriteAllText(temporaryPath, JsonSerializer.Serialize(settings, JsonOptions));
        File.Move(temporaryPath, _path, true);
    }

    private void QuarantineCorruptedSettings()
    {
        try
        {
            var corruptedPath = Path.Combine(_directory, $"settings.corrupt-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}.json");
            File.Move(_path, corruptedPath, false);
        }
        catch (IOException ex)
        {
            Trace.TraceWarning("MotionCue could not quarantine corrupted settings: {0}", ex.Message);
        }
        catch (UnauthorizedAccessException ex)
        {
            Trace.TraceWarning("MotionCue could not access corrupted settings: {0}", ex.Message);
        }
    }
}
