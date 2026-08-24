[CmdletBinding()]
param(
    [string]$RepositoryRoot = '',
    [int]$LockWaitSeconds = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}

$logDirectory = Join-Path $env:LOCALAPPDATA 'MotionCue'
$logPath = Join-Path $logDirectory 'git-autosync.log'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null

function Write-AutosyncLog([string]$Message) {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss KST'
    Add-Content -LiteralPath $logPath -Value "$timestamp $Message"
}

function Invoke-Git([string[]]$Arguments) {
    & git -C $RepositoryRoot @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }
}

try {
    if (-not (Test-Path -LiteralPath (Join-Path $RepositoryRoot '.git'))) {
        throw "No Git repository at $RepositoryRoot."
    }

    $gitDirectory = Join-Path $RepositoryRoot '.git'
    $inProgress = @('MERGE_HEAD', 'REBASE_HEAD', 'CHERRY_PICK_HEAD', 'rebase-merge', 'rebase-apply', 'index.lock') |
        Where-Object { Test-Path -LiteralPath (Join-Path $gitDirectory $_) }
    if ($inProgress) {
        Write-AutosyncLog "PAUSED: Git operation in progress ($($inProgress -join ', ')). Resolve it manually; no files were changed."
        exit 2
    }

    if ($LockWaitSeconds -gt 0) {
        Start-Sleep -Seconds $LockWaitSeconds
    }

    Invoke-Git @('fetch', 'origin', '--prune')

    $dirty = & git -C $RepositoryRoot status --porcelain
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to inspect Git status.'
    }

    if ($dirty) {
        Invoke-Git @('add', '-A')
        $staged = & git -C $RepositoryRoot diff --cached --quiet
        if ($LASTEXITCODE -eq 1) {
            $message = 'autosync(windows): ' + (Get-Date -Format 'yyyy-MM-dd HH:mm KST')
            Invoke-Git @('commit', '-m', $message)
            Write-AutosyncLog "SNAPSHOT: $message"
        }
        elseif ($LASTEXITCODE -gt 1) {
            throw 'Unable to inspect staged changes.'
        }
    }

    $counts = (& git -C $RepositoryRoot rev-list --left-right --count 'HEAD...origin/main').Trim().Split([char[]]" `t", [System.StringSplitOptions]::RemoveEmptyEntries)
    $ahead = [int]$counts[0]
    $behind = [int]$counts[1]

    if ($behind -gt 0) {
        Invoke-Git @('rebase', 'origin/main')
        Write-AutosyncLog "PULL: rebased $behind remote commit(s) onto local work."
    }

    $remainingAhead = [int]((& git -C $RepositoryRoot rev-list --left-right --count 'HEAD...origin/main').Trim().Split([char[]]" `t", [System.StringSplitOptions]::RemoveEmptyEntries)[0])
    if ($remainingAhead -gt 0) {
        Invoke-Git @('push', 'origin', 'main')
        Write-AutosyncLog "PUSH: published $remainingAhead local commit(s)."
    }
    else {
        Write-AutosyncLog 'IDLE: repository already synchronized.'
    }
}
catch {
    Write-AutosyncLog "ERROR: $($_.Exception.Message)"
    exit 1
}
