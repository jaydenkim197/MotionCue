using System.Diagnostics;
using System.IO;
using System.Text;
using MotionCue.Motion;
using MotionCue.Research;
using MotionCue.Windows.AppServices;

namespace MotionCue.Windows.Research;

public sealed class ResearchSessionService : IDisposable
{
    private readonly object _gate = new();
    private readonly MotionController _controller;
    private readonly SynchronizationContext _uiContext;
    private readonly System.Threading.Timer _fmsTimer;
    private readonly string _outputDirectory;
    private StreamWriter? _writer;
    private ResearchSessionConfig? _config;
    private DateTimeOffset _startedAt;
    private DateTimeOffset? _nextFmsAt;
    private bool _disposed;

    public ResearchSessionService(MotionController controller, string? outputDirectory = null)
    {
        _controller = controller;
        _uiContext = SynchronizationContext.Current ?? new SynchronizationContext();
        _outputDirectory = outputDirectory ?? GetDefaultOutputDirectory();
        _fmsTimer = new System.Threading.Timer(OnFmsTimer, null, Timeout.InfiniteTimeSpan, Timeout.InfiniteTimeSpan);
        _controller.CueFrameChanged += OnCueFrameChanged;
        _controller.SourceStatusChanged += OnSourceStatusChanged;
    }

    public bool IsActive
    {
        get
        {
            lock (_gate)
            {
                return _config is not null;
            }
        }
    }

    public ResearchSessionConfig? ActiveConfig { get { lock (_gate) { return _config; } } }
    public DateTimeOffset? StartedAt { get { lock (_gate) { return _config is null ? null : _startedAt; } } }
    public DateTimeOffset? NextFmsAt { get { lock (_gate) { return _nextFmsAt; } } }
    public string? OutputPath { get; private set; }

    public event EventHandler? SessionChanged;
    public event EventHandler? FmsDue;

    public void StartSession(ResearchSessionConfig config)
    {
        ObjectDisposedException.ThrowIf(_disposed, this);
        config.Validate();
        if (IsActive)
        {
            throw new InvalidOperationException("A research session is already active.");
        }

        var temporarySettings = config.Condition switch
        {
            ResearchCondition.NoCue => _controller.Settings with { Mode = MotionCueMode.Off, Pattern = CuePattern.Regular },
            ResearchCondition.StaticVisualControl => _controller.Settings with { Mode = MotionCueMode.On, Pattern = CuePattern.Regular },
            ResearchCondition.SynchronizedCue => _controller.Settings with { Mode = MotionCueMode.On, Pattern = CuePattern.Regular },
            _ => throw new ArgumentOutOfRangeException(nameof(config), config.Condition, null)
        };

        _controller.BeginTemporarySettings(temporarySettings, config.Condition == ResearchCondition.StaticVisualControl);
        try
        {
            Directory.CreateDirectory(_outputDirectory);
            var timestamp = DateTimeOffset.UtcNow.ToString("yyyyMMdd-HHmmss");
            var fileName = $"{timestamp}_{config.ParticipantCode}_{config.SessionId}_{config.Condition}.csv";
            var outputPath = Path.Combine(_outputDirectory, fileName);
            var stream = new FileStream(outputPath, FileMode.CreateNew, FileAccess.Write, FileShare.Read);
            var writer = new StreamWriter(stream, new UTF8Encoding(false)) { AutoFlush = true };
            writer.WriteLine(ResearchCsvFormatter.Header);

            lock (_gate)
            {
                _writer = writer;
                _config = config;
                _startedAt = DateTimeOffset.UtcNow;
                _nextFmsAt = _startedAt + config.FmsInterval;
                OutputPath = outputPath;
                WriteRecordLocked(ResearchRecordType.SessionStarted, note: "Research session started");
            }

            _fmsTimer.Change(config.FmsInterval, config.FmsInterval);
            RaiseSessionChanged();
        }
        catch
        {
            _controller.EndTemporarySettings(forceOff: false);
            throw;
        }
    }

    public void RecordFms(int score)
    {
        if (score is < 0 or > 20)
        {
            throw new ArgumentOutOfRangeException(nameof(score), "FMS must be between 0 and 20.");
        }

        lock (_gate)
        {
            EnsureActive();
            WriteRecordLocked(ResearchRecordType.FmsRating, fmsScore: score, note: "FMS rating");
        }
    }

    public void AddMarker(string note)
    {
        if (string.IsNullOrWhiteSpace(note))
        {
            throw new ArgumentException("Marker text is required.", nameof(note));
        }
        if (note.Length > 200)
        {
            throw new ArgumentException("Marker text must be 200 characters or fewer.", nameof(note));
        }

        lock (_gate)
        {
            EnsureActive();
            WriteRecordLocked(ResearchRecordType.EventMarker, note: note.Trim());
        }
    }

    public void StopSession(bool emergency, string note)
    {
        StreamWriter? writer;
        lock (_gate)
        {
            if (_config is null)
            {
                return;
            }

            WriteRecordLocked(
                emergency ? ResearchRecordType.EmergencyStop : ResearchRecordType.SessionEnded,
                note: string.IsNullOrWhiteSpace(note) ? (emergency ? "Emergency stop" : "Session completed") : note.Trim());
            writer = _writer;
            _writer = null;
            _config = null;
            _nextFmsAt = null;
        }

        _fmsTimer.Change(Timeout.InfiniteTimeSpan, Timeout.InfiniteTimeSpan);
        writer?.Dispose();
        _controller.EndTemporarySettings(forceOff: emergency);
        RaiseSessionChanged();
    }

    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }
        _disposed = true;
        StopSession(emergency: false, "Application closed");
        _fmsTimer.Dispose();
        _controller.CueFrameChanged -= OnCueFrameChanged;
        _controller.SourceStatusChanged -= OnSourceStatusChanged;
    }

    private void OnCueFrameChanged(object? sender, CueFrame frame)
    {
        lock (_gate)
        {
            if (_config is not null)
            {
                WriteRecordLocked(ResearchRecordType.MotionState, frame: frame);
            }
        }
    }

    private void OnSourceStatusChanged(object? sender, MotionSourceStatus status)
    {
        lock (_gate)
        {
            if (_config is not null)
            {
                WriteRecordLocked(ResearchRecordType.SourceStatus, sourceStatus: status, note: status.Message);
            }
        }
    }

    private void OnFmsTimer(object? state)
    {
        lock (_gate)
        {
            if (_config is null)
            {
                return;
            }
            _nextFmsAt = DateTimeOffset.UtcNow + _config.FmsInterval;
            WriteRecordLocked(ResearchRecordType.EventMarker, note: "FMS prompt due");
        }

        _uiContext.Post(_ => FmsDue?.Invoke(this, EventArgs.Empty), null);
        RaiseSessionChanged();
    }

    private void WriteRecordLocked(
        ResearchRecordType recordType,
        CueFrame? frame = null,
        MotionSourceStatus? sourceStatus = null,
        int? fmsScore = null,
        string note = "")
    {
        if (_writer is null || _config is null)
        {
            return;
        }

        var now = DateTimeOffset.UtcNow;
        var motion = _controller.CurrentState;
        var cue = frame ?? _controller.CurrentFrame;
        var status = sourceStatus ?? _controller.SourceStatus;
        var record = new ResearchRecord(
            now,
            Math.Max(0, (now - _startedAt).TotalSeconds),
            recordType,
            _config.ParticipantCode,
            _config.SessionId,
            _config.ProtocolVersion,
            _config.Condition,
            _controller.ActiveSourceName,
            status.Availability,
            status.SourceKind,
            motion.SampleInterval?.TotalSeconds,
            motion.LongitudinalRaw,
            motion.LongitudinalFiltered,
            motion.LateralRaw,
            motion.LateralFiltered,
            motion.ActivationConfidence,
            motion.AutomaticCuesActive,
            cue.Visible,
            cue.HorizontalOffset,
            cue.VerticalOffset,
            cue.Intensity,
            motion.SampleAccepted,
            motion.SampleStatus,
            fmsScore,
            note);
        _writer.WriteLine(ResearchCsvFormatter.Format(record));
    }

    private void EnsureActive()
    {
        if (_config is null)
        {
            throw new InvalidOperationException("No research session is active.");
        }
    }

    private void RaiseSessionChanged() => _uiContext.Post(_ => SessionChanged?.Invoke(this, EventArgs.Empty), null);

    private static string GetDefaultOutputDirectory()
    {
        var documents = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
        if (!string.IsNullOrWhiteSpace(documents))
        {
            return Path.Combine(documents, "MotionCue Research Data");
        }

        return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "MotionCue", "ResearchSessions");
    }
}
