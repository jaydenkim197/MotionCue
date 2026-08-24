# Mac Git autosync setup

This is the Mac counterpart to the Windows GitHub-only autosync. It intentionally does **not** use Syncthing, a shared cloud-drive workspace, or USB cut/paste as live source control.

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

Then implement the Mac companion autosync:
- Add a tracked script at tools/git-autosync-mac.sh.
- Use a LaunchAgent at ~/Library/LaunchAgents/com.jayden.motioncue.git-autosync.plist to invoke it every 120 seconds after user login.
- Keep logs outside the repository at ~/Library/Logs/MotionCue/git-autosync.log.
- On each run: stop without modifying files if Git has a merge, rebase, cherry-pick, or index-lock in progress; otherwise fetch origin; if the working tree changed, make exactly one `autosync(mac): YYYY-MM-DD HH:mm KST` commit; rebase onto origin/main only when needed; then push if ahead.
- Never force push, reset, discard, auto-resolve a conflict, or overwrite a user file. On conflict, preserve all work, stop the automation, and write an actionable log entry.
- Do not commit derived data, xcuserdata, .DS_Store, resource-fork files, build output, certificates, provisioning profiles, or secrets. Respect this repository's .gitignore and .gitattributes.
- Ensure the LaunchAgent can run on battery and is scoped to the logged-in user.
- Run the script once manually, verify its log and clean Git status, then load/start the LaunchAgent.
- Record every material decision and actual verification result in docs/development-log.md, commit, and push it.

After setup, report: clone location, Git/remote status, LaunchAgent label and schedule, script/log locations, initial run result, Xcode project opening result, and any user action still required.
```

## Operating boundary

Automatic snapshots reduce routine handoff work but are not a distributed live-editing system. Do not let Windows Codex and Mac Codex edit the same file simultaneously. When a conflict occurs, resolve it deliberately before re-enabling the matching autosync task.
