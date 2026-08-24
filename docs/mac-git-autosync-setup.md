# Mac Git autosync setup

This is the Mac counterpart to the Windows GitHub-only completion sync. It intentionally does **not** use Syncthing, a shared cloud-drive workspace, USB cut/paste as live source control, or a continuous background watcher.

## Prerequisite

The Windows baseline is published on private GitHub repository `https://github.com/jaydenkim197/MotionCue.git`, branch `main`. The Mac must use a fresh clone, not its older USB-copied folder, as the live workspace.

## Prompt for Mac Codex

```text
Set up the Mac side of the MotionCue GitHub-only autosync workflow. Do not install or configure Syncthing, and do not use iCloud Drive, Dropbox, OneDrive, or a USB folder as a live source-code workspace.

Repository: https://github.com/jaydenkim197/MotionCue.git
Target workspace: /Users/jayden/vehicle_mode_for_laptop
Branch: main
Git author: Jayden Kim <jaydenkim197@users.noreply.github.com>

First perform a non-destructive diagnosis:
- Inspect the existing /Users/jayden/vehicle_mode_for_laptop folder.
- If it has local files or unpushed changes, preserve it by renaming it with a timestamp; do not delete it.
- Clone the GitHub private repository into the target workspace and verify `git status -sb`, `origin`, `mobile/ios/MotionCueSensor`, `src/MotionCue.Core`, `src/MotionCue.Windows`, and docs/development-log.md.
- Confirm Xcode can still open the cloned iOS project. Never copy a .git directory from another computer.

Then implement the Mac companion completion-sync helper:
- Add a tracked script at tools/git-autosync-mac.sh.
- Keep logs outside the repository at ~/Library/Logs/MotionCue/git-autosync.log.
- On each run: stop without modifying files if Git has a merge, rebase, cherry-pick, or index-lock in progress; otherwise fetch origin; if the working tree changed, make exactly one `autosync(mac): YYYY-MM-DD HH:mm KST` commit; rebase onto origin/main only when needed; then push if ahead.
- Never force push, reset, discard, auto-resolve a conflict, or overwrite a user file. On conflict, preserve all work, stop the automation, and write an actionable log entry.
- Do not commit derived data, xcuserdata, .DS_Store, resource-fork files, build output, certificates, provisioning profiles, or secrets. Respect this repository's .gitignore and .gitattributes.
- Run the script once manually, verify its log and clean Git status. Do not create a LaunchAgent, scheduled task, file watcher, or polling process.
- Add an explicit instruction to the Mac Codex task: run this helper after each material code or document change, immediately before its final report.
- Record every material decision and actual verification result in docs/development-log.md, commit, and push it.

After setup, report: clone location, Git/remote status, script/log locations, initial run result, Xcode project opening result, and any user action still required.
```

## Operating boundary

Completion sync reduces routine handoff work but is not a distributed live-editing system. Use one Codex task at a time. When a conflict occurs, resolve it deliberately before running the helper again.
