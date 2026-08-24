# MotionCue cross-platform Git workflow

## Decision

MotionCue uses one **private GitHub repository** with separate local working copies on Windows and macOS. A shared cloud-drive folder and live filesystem synchronization are not used for the source tree.

```text
GitHub private repository (main)
        ↑ push                 ↓ pull
Windows local clone       Mac local clone
src/ + tests + docs       mobile/ios/ + docs
```

This repository is the single source of truth for the shared protocol, implementation history, and research documents. USB is a transport and offline backup only; it is not the collaboration mechanism.

## Ownership and shared boundaries

| Area | Primary workstation | Rule |
|---|---|---|
| `src/MotionCue.Core/`, `src/MotionCue.Windows/`, `tests/` | Windows | macOS reads these as the receiver/protocol contract; do not casually change SensorFrame compatibility |
| `mobile/ios/MotionCueSensor/` | Mac | Windows reads this as the sender implementation; iOS build products are never committed |
| `docs/`, `paper/`, `README.md`, `.gitignore` | Both | Pull before editing; resolve conflicts deliberately; append material decisions to development log |
| `artifacts/`, `.tools/`, `bin/`, `obj/`, Xcode user data | Neither | Generated or local-only; ignored by Git |

## Normal handoff

1. Start a work session with `git pull --ff-only`.
2. Make one coherent change.
3. Update `docs/development-log.md` when the product, protocol, experiment, or implementation state changes.
4. Inspect `git status`, then commit a concise message.
5. Push to `main`.
6. The other computer pulls before beginning related work.

Do not edit the same shared document on both computers before pulling. For urgent parallel work, keep Windows changes in `src/` and Mac changes in `mobile/ios/`, then make documentation changes sequentially.

## Optional automatic snapshots

Windows runs `tools/git-autosync.ps1` through a per-user Scheduled Task every two minutes. It fetches GitHub, makes one `autosync(windows)` snapshot only when the working tree changed, rebases only when Git can do so normally, and pushes the result. It does not use Syncthing and never overwrites a merge/rebase conflict: it pauses, preserves all files, and logs the reason to `%LOCALAPPDATA%\MotionCue\git-autosync.log`.

The Mac should use the same policy through a `launchd` job, with `autosync(mac)` commit messages. Both automations must be stopped before an intentional history rewrite, mass refactor, or direct conflict resolution.

## Initial publication

1. Create a private GitHub repository named `MotionCue` with no generated README, license, or `.gitignore`.
2. Configure the desired Git author name and email on each computer.
3. Add the GitHub repository as `origin`.
4. Commit the current portable source, documents, tests, iOS project, and thesis source.
5. Push `main` from Windows.
6. On the Mac, archive or rename the USB-copied working folder, then clone the private repository into a normal local development folder.
7. Build the relevant platform and confirm the repository is clean on each computer.

## Prohibited synchronization targets

- Do not put the live repository inside OneDrive, iCloud Drive, Dropbox, or a Syncthing mirror. Do not synchronize a Git working tree with Syncthing while another machine also has an independent Git automation process.
- Do not commit certificates, provisioning profiles, Apple account material, `.xcuserdata`, `DerivedData`, `.tools`, `bin`, `obj`, or released executables.
- Do not use USB `cut`/`paste` as a source-control substitute. Copy it only as an offline backup.
