#!/bin/bash
# Isolated local/bare repository fixtures; never contacts GitHub or alters user work.
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$task_root/artifacts"
fixture="$(mktemp -d "$task_root/artifacts/sync-fixture.XXXXXX")"
export MOTIONCUE_SYNC_LOG_DIRECTORY="$fixture/logs"
git init --bare --initial-branch=main "$fixture/remote.git" >/dev/null
git clone "$fixture/remote.git" "$fixture/mac" >/dev/null 2>&1
git -C "$fixture/mac" config user.name "Fixture"
git -C "$fixture/mac" config user.email "fixture@example.invalid"
git -C "$fixture/mac" commit --allow-empty -m initial >/dev/null
git -C "$fixture/mac" push -u origin main >/dev/null 2>&1
git -C "$fixture/mac" update-ref REBASE_HEAD HEAD
bash "$task_root/tools/git-autosync-mac.sh" "$fixture/mac" >/dev/null
echo "PASS stale REBASE_HEAD does not block a completed rebase"

assert_paused() {
    local result
    set +e
    bash "$task_root/tools/git-autosync-mac.sh" "$fixture/mac" >/dev/null 2>&1
    result=$?
    set -e
    test "$result" -eq 2
}
for operation in rebase-merge rebase-apply; do
    mkdir "$fixture/mac/.git/$operation"
    assert_paused
    rmdir "$fixture/mac/.git/$operation"
    echo "PASS active $operation pauses"
done
for operation in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD; do
    touch "$fixture/mac/.git/$operation"
    assert_paused
    unlink "$fixture/mac/.git/$operation"
    echo "PASS active $operation pauses"
done
touch "$fixture/mac/.git/index.lock"
assert_paused
# Empty fixture lock only. It cannot belong to any external Git process.
unlink "$fixture/mac/.git/index.lock"
echo "PASS index lock pauses"

git -C "$fixture/mac" switch -c codex/fixture >/dev/null 2>&1
assert_paused
git -C "$fixture/mac" switch main >/dev/null 2>&1
echo "PASS non-main branch pauses"

git clone "$fixture/remote.git" "$fixture/windows" >/dev/null 2>&1
git -C "$fixture/windows" config user.name "Fixture"
git -C "$fixture/windows" config user.email "fixture@example.invalid"
git -C "$fixture/windows" commit --allow-empty -m windows-change >/dev/null
git -C "$fixture/windows" push >/dev/null 2>&1
git -C "$fixture/mac" commit --allow-empty -m mac-change >/dev/null
bash "$task_root/tools/git-autosync-mac.sh" "$fixture/mac" >/dev/null
test "$(git -C "$fixture/mac" rev-parse HEAD)" = "$(git --git-dir="$fixture/remote.git" rev-parse main)"
echo "PASS divergent non-conflicting commits preserved and pushed"
echo "Fixture retained for audit: $fixture"
