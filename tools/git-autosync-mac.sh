#!/bin/bash
# Completion-only GitHub sync for the Mac MotionCue working copy.
# Run after a material code or documentation change, before reporting completion.

set -u
set -o pipefail

repository_root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
log_directory="${MOTIONCUE_SYNC_LOG_DIRECTORY:-$HOME/Library/Logs/MotionCue}"
log_path="$log_directory/git-autosync.log"

mkdir -p "$log_directory"

timestamp() {
    TZ=Asia/Seoul date '+%Y-%m-%d %H:%M:%S KST'
}

write_log() {
    printf '%s %s\n' "$(timestamp)" "$1" >> "$log_path"
}

fail() {
    write_log "ERROR: $1"
    printf '%s\n' "$1" >&2
    exit 1
}

run_git() {
    git -C "$repository_root" "$@" || fail "git $* failed; all files were preserved."
}

if ! git -C "$repository_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    fail "No Git repository at $repository_root."
fi

git_directory="$(git -C "$repository_root" rev-parse --path-format=absolute --git-dir)" \
    || fail "Unable to locate the Git directory."

# REBASE_HEAD can survive a completed rebase; the rebase directories indicate an
# active operation. Do not mistake that historical pseudoref for an active lock.
for operation in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-merge rebase-apply index.lock; do
    if [ -e "$git_directory/$operation" ]; then
        write_log "PAUSED: Git operation in progress ($operation). Resolve it manually; no files were changed."
        exit 2
    fi
done

if [ "$(git -C "$repository_root" branch --show-current)" != "main" ]; then
    write_log "PAUSED: completion-sync requires main; no files were changed."
    exit 2
fi

run_git fetch origin --prune

if [ -n "$(git -C "$repository_root" status --porcelain)" ]; then
    run_git add -A
    if ! git -C "$repository_root" diff --cached --quiet; then
        commit_message="autosync(mac): $(TZ=Asia/Seoul date '+%Y-%m-%d %H:%M KST')"
        run_git commit -m "$commit_message"
        write_log "SNAPSHOT: $commit_message"
    fi
fi

read -r ahead behind < <(git -C "$repository_root" rev-list --left-right --count HEAD...origin/main) \
    || fail "Unable to compare HEAD with origin/main."

if [ "$behind" -gt 0 ]; then
    if ! git -C "$repository_root" rebase origin/main; then
        write_log "PAUSED: rebase onto origin/main stopped. Resolve the conflict manually; no files were discarded."
        exit 2
    fi
    write_log "PULL: rebased $behind remote commit(s) onto local work."
fi

read -r ahead behind < <(git -C "$repository_root" rev-list --left-right --count HEAD...origin/main) \
    || fail "Unable to compare the rebased branch with origin/main."

if [ "$ahead" -gt 0 ]; then
    run_git push origin main
    write_log "PUSH: published $ahead local commit(s)."
else
    write_log "IDLE: repository already synchronized."
fi
