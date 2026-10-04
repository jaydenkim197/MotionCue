#!/bin/bash
# Read only MotionCue's bounded app diagnostics; do not attach a debugger.
set -euo pipefail

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
    printf 'Usage: bash tools/collect-ios-runtime-logs.sh <paired-device-id>\n' >&2
    exit 2
fi

device_id="$1"
repository_root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$repository_root/artifacts"
capture_directory="$(mktemp -d "$repository_root/artifacts/ios-runtime-$(date '+%Y%m%d-%H%M%S')-XXXXXX")"
app_log_directory='Library/Application Support/Diagnostics'

xcrun devicectl device copy from --timeout 30 --device "$device_id" \
    --domain-type appDataContainer --domain-identifier com.motioncue.sensor \
    --source "$app_log_directory/runtime.jsonl" \
    --destination "$capture_directory/runtime.jsonl"

if ! xcrun devicectl device copy from --timeout 30 --device "$device_id" \
    --domain-type appDataContainer --domain-identifier com.motioncue.sensor \
    --source "$app_log_directory/runtime-previous.jsonl" \
    --destination "$capture_directory/runtime-previous.jsonl"; then
    printf 'Previous log not copied (normal before first rotation); current log is preserved.\n' >&2
fi

printf 'Local capture: %s\n' "$capture_directory"
printf 'No device files were changed; captures under artifacts are not Git-synced.\n'
