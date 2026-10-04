# Reusable GitHub Completion-Sync Workflow

> A low-overhead, two-computer Git workflow for one person who works sequentially on a Windows PC and a Mac.  
> Template status: reusable outside MotionCue. Replace every `<placeholder>` before applying it to another project.

## 1. What this workflow solves

This workflow keeps **two independent local workspaces** synchronized through one private GitHub repository:

```text
                    GitHub private repository
                             main
                       ↑ push     ↓ fetch/rebase
                  ┌─────────────────────┐
                  │                     │
          Windows local clone      Mac local clone
```

It is designed for a single owner who changes one computer at a time, especially when coding agents make most edits. It replaces USB copying, shared cloud folders, and continuous synchronization with a single action at the **end of a meaningful task**.

The central idea is not “keep two folders identical every second.” It is “make GitHub the source of truth after each completed change.”

## 2. MotionCue deployment: the current concrete implementation

| Item | Current MotionCue value |
|---|---|
| Remote | `https://github.com/jaydenkim197/MotionCue.git` (private) |
| Shared branch | `main` |
| Windows workspace | `C:\Users\sukhe\Desktop\vehicle_mode_for_laptop` |
| Mac workspace | `/Users/jayden/vehicle_mode_for_laptop` |
| Windows helper | `tools/git-autosync.ps1` |
| Mac helper | `tools/git-autosync-mac.sh` |
| Windows log | `%LOCALAPPDATA%\MotionCue\git-autosync.log` |
| Mac log | `~/Library/Logs/MotionCue/git-autosync.log` |
| Trigger | Codex runs the helper once immediately before reporting a material task complete |
| Background service | None — no Task Scheduler, LaunchAgent, file watcher, polling, Syncthing, or cloud-drive workspace mirror |

The helpers are tracked in the repository so the operating policy travels with the project.

## 3. Preconditions and operating conditions

Use this workflow only when these conditions are true:

- The same person owns both computers or the team explicitly agrees to sequential editing.
- Both machines have Git, authenticated push access to the same GitHub repository, and a normal local clone.
- The working tree is **not** inside OneDrive, iCloud Drive, Dropbox, Google Drive, Syncthing, or a similar live-sync folder.
- Each change is reasonably coherent: code plus the directly affected tests/documents.
- A user or agent checks Git state before starting a conflicting edit to shared files.
- The project has a maintained `.gitignore` for build output, editor metadata, secrets, caches, and OS-specific temporary files.
- The repository uses a stable line-ending policy. MotionCue uses `.gitattributes` with `* text=auto eol=lf`.

This is a poor fit for simultaneous editing of the same files by multiple people. Use pull requests, branches, or a more deliberate team workflow in that case.

## 4. Deliberate non-goals

The helpers do **not** provide live collaboration or automatic conflict resolution.

- No filesystem replication occurs between computers.
- No background process notices every save.
- No force-push, `reset --hard`, automatic `checkout`, automatic merge conflict resolution, or file discard is allowed.
- A helper never copies a `.git` directory from one computer to another.
- USB is acceptable as an offline backup, but only with copy semantics; it is not the live source-control channel.

These restrictions are intentional. Generated files and `.git` internals are prone to corruption when ordinary sync tools race across two computers.

## 5. One-time setup for another project

### 5.1 Create and publish the first workspace

On the computer containing the baseline project:

```bash
git init
git branch -M main
git remote add origin <YOUR_PRIVATE_GITHUB_REPOSITORY_URL>
git add -A
git commit -m "Initial project baseline"
git push -u origin main
```

Before the first commit, add a project-appropriate `.gitignore` and `.gitattributes`. At minimum, exclude build folders, dependency caches, editor user data, secrets, signing material, and generated artifacts. Do not blindly copy MotionCue’s ignore rules if another project has different generated files.

### 5.2 Clone on the second computer

Do not move a USB workspace into the final location and do not transplant its `.git` folder. Instead:

1. Preserve any existing folder by renaming or archiving it if it contains work.
2. Clone GitHub into a normal local developer folder.
3. Confirm `git status -sb`, `git remote -v`, the expected branch, and the relevant platform build.

```bash
git clone <YOUR_PRIVATE_GITHUB_REPOSITORY_URL> <LOCAL_WORKSPACE_PATH>
cd <LOCAL_WORKSPACE_PATH>
git status -sb
git remote -v
```

### 5.3 Configure identity and authentication

Configure the desired author identity on each machine. Use GitHub HTTPS credentials, an SSH key, or another approved authentication method. Authentication setup is outside the helper: the helper assumes a normal `git fetch` and `git push` already work interactively.

```bash
git config user.name "<YOUR_NAME>"
git config user.email "<YOUR_GIT_EMAIL_OR_NOREPLY_ADDRESS>"
```

If using SSH on a Mac with a project-specific key, prefer a dedicated host alias in `~/.ssh/config` rather than replacing unrelated GitHub keys.

## 6. Completion-sync algorithm

Both MotionCue helpers implement the same sequence.

```text
1. Verify this is a Git working tree.
2. Refuse to continue if merge/rebase/cherry-pick/index-lock state exists.
3. Fetch origin --prune.
4. If the working tree is dirty:
       git add -A
       create one timestamped autosync(<platform>) snapshot commit
5. Compare HEAD with origin/main.
6. If behind:
       git rebase origin/main
       stop immediately if a conflict occurs.
7. If ahead:
       git push origin main
8. Write an external log entry and return a meaningful exit code.
```

The important ordering is **fetch → snapshot local work → rebase remote work → push**. A local task is committed before the remote branch is replayed beneath it, so a conflict stops with both versions preserved in Git rather than silently overwriting either one.

### 6.1 States that force a safe pause

The helper requires main and checks these Git-operation markers before it changes anything. REBASE_HEAD alone is historical state and can remain after a successful rebase; the active rebase directories are the safe pause markers:

- `MERGE_HEAD`
- `REVERT_HEAD`
- `CHERRY_PICK_HEAD`
- `rebase-merge`
- `rebase-apply`
- `index.lock`

If one is present, it writes `PAUSED` to the log and exits with code `2`. The user or agent must inspect `git status`, resolve or abort the intentional Git operation explicitly, then rerun the helper.

### 6.2 Exit-code convention

| Exit code | Meaning | Expected next action |
|---|---|---|
| `0` | Sync completed or repository was already current | Continue on the other computer after fetching/pulling as normal |
| `1` | Git/auth/network/command error | Read the external log and fix the underlying problem; no automatic overwrite occurred |
| `2` | A Git operation or conflict requires deliberate resolution | Inspect `git status`; resolve manually; rerun after the repository is clean |

## 7. MotionCue helper details

### 7.1 Windows: `tools/git-autosync.ps1`

The Windows helper:

- accepts `RepositoryRoot` and optional `LockWaitSeconds` parameters;
- uses `git -C <root>` so it can run from any shell location;
- creates `autosync(windows): YYYY-MM-DD HH:mm KST` only if there are staged changes after `git add -A`;
- logs outside the repository at `%LOCALAPPDATA%\MotionCue\git-autosync.log`;
- uses PowerShell strict mode and exits on errors.

Run from the repository root:

```powershell
.\tools\git-autosync.ps1
```

For reuse, copy the helper, change the log folder from `MotionCue` to your project name, and keep the safety checks unchanged.

### 7.2 macOS: `tools/git-autosync-mac.sh`

The Mac helper:

- derives the repository root from its own directory unless an explicit first argument is provided;
- uses `set -u` and `set -o pipefail`;
- creates `autosync(mac): YYYY-MM-DD HH:mm KST` snapshot commits only when needed;
- logs outside the repository at `~/Library/Logs/MotionCue/git-autosync.log`;
- writes a clear preservation message whenever a Git command fails.

Run from the repository root:

```bash
chmod +x tools/git-autosync-mac.sh   # one time if needed
./tools/git-autosync-mac.sh
```

For reuse, copy the helper, change the log folder from `MotionCue` to your project name, and retain its pause-on-conflict behavior.

## 8. Daily handoff protocol

### Windows → Mac

1. Finish one material Windows task.
2. Update affected documentation and tests.
3. Run the Windows helper once.
4. Confirm `git status -sb` is clean and `main` matches `origin/main`.
5. On the Mac, fetch/pull or run the Mac helper before starting related work.

### Mac → Windows

1. Finish one material iOS/macOS/documentation task.
2. Update affected documentation and tests.
3. Run the Mac helper once.
4. Confirm a clean working tree.
5. On Windows, fetch/pull or run the Windows helper before starting related work.

### Shared-file rule

Files such as `docs/`, root configuration, shared protocol definitions, and project manifests have a higher conflict risk. Pull before editing them. If both machines must make a shared-document change, make the edits sequentially rather than relying on automatic merge behavior.

## 9. Conflict and recovery procedure

When a helper returns `2` or an automatic rebase stops:

1. Stop editing on the other computer.
2. Read `git status` and the external helper log.
3. Inspect the conflict markers and the commits on both sides.
4. Edit the conflicting files so that the intended content from both sides is preserved.
5. Stage only the resolved files with `git add <path>`.
6. Continue the Git operation (`git rebase --continue` or the relevant command).
7. Run tests/build checks appropriate to the changed areas.
8. Rerun the completion-sync helper.

Never resolve a conflict with `git reset --hard`, a force push, or an indiscriminate checkout unless that data loss is explicitly intended and backed up.

If `git status` says no rebase is active but a stale operation marker blocks the helper, first inspect Git state. Only after verifying there is no active operation should a knowledgeable operator remove the single stale marker. Record that intervention in the project log.

## 10. Recommended repository structure

Use ownership boundaries to reduce overlap, not as access control:

```text
<project>/
├─ src/                 # primary desktop/backend implementation
├─ mobile/ios/          # iOS implementation
├─ mobile/android/      # optional Android implementation
├─ docs/                # shared decisions, architecture, handoff notes
├─ tests/               # shared/primary tests
├─ tools/               # tracked completion-sync helpers
├─ .gitignore
└─ .gitattributes
```

For MotionCue, Windows primarily owns `src/` and `tests/`, while the Mac primarily owns `mobile/ios/`. Both workspaces may change `docs/`, but they do so sequentially.

## 11. Reuse checklist

Copy this workflow to another project only after all boxes are true:

- [ ] A private remote repository and `main` branch exist.
- [ ] Each computer has its own normal local clone.
- [ ] Push authentication works manually on both computers.
- [ ] `.gitignore` excludes generated files, secrets, platform metadata, and build output.
- [ ] `.gitattributes` defines a line-ending policy.
- [ ] Windows and Mac helper scripts are added under `tools/`, marked executable where needed, and use a project-specific external log directory.
- [ ] The helpers pause on Git-operation markers and never force-push or auto-resolve conflicts.
- [ ] No scheduled task, LaunchAgent, watcher, or filesystem-sync tool is enabled for the repository.
- [ ] Everyone using the workflow understands that a `2` exit code means “resolve deliberately,” not “rerun until it works.”
- [ ] A first manual run on each computer completes with clean `git status -sb` output.

## 12. Related MotionCue documents

- [MotionCue cross-platform Git workflow](cross-platform-git-workflow.md) — project-specific boundaries and operating policy.
- [Mac Git autosync setup](mac-git-autosync-setup.md) — original Mac clone/setup prompt for this project.
- [Development log](development-log.md) — historical decisions and actual sync incidents.
