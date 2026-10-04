[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$bundledSdk = Join-Path $repositoryRoot '.tools\dotnet8\dotnet.exe'
if (Test-Path -LiteralPath $bundledSdk) { $sdk = $bundledSdk }
else { $sdk = (Get-Command dotnet -ErrorAction Stop).Source }

Push-Location $repositoryRoot
try {
    & $sdk test tests/MotionCue.Core.Tests -c Release
    if ($LASTEXITCODE -ne 0) { throw 'Core tests failed; no release was published.' }
    & $sdk publish src/MotionCue.Windows -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o artifacts\MotionCue-win-x64
    if ($LASTEXITCODE -ne 0) { throw 'Windows publish failed; do not use the previous EXE.' }
    $exe = Join-Path $repositoryRoot 'artifacts\MotionCue-win-x64\MotionCue.Windows.exe'
    $revision = (& git rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Unable to identify source revision.' }
    $dirty = [bool](& git status --porcelain)
    $manifest = [ordered]@{
        Version = '0.2.0'
        SourceRevision = $revision
        WorktreeDirty = $dirty
        BuiltAtUtc = [DateTime]::UtcNow.ToString('O')
        Sha256 = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
        RuntimeValidated = $false
    }
    $manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path (Split-Path $exe) 'build-manifest.json') -Encoding utf8
    Write-Host "Built: $exe"
    Write-Host 'Build success is not BLE/runtime verification. Run the bench checklist before driving.'
}
finally { Pop-Location }
