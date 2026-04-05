# Bootstrap Architecture

How a developer goes from a fresh machine to a working project.

## Layers

```
┌─────────────────────────────────────────────┐
│  Machine provisioning                       │  OS, drivers, Docker
│  (IT/admin, rarely)                         │
├─────────────────────────────────────────────┤
│  intui-setup-access                         │  curl, git, gh, ssh, direnv
│  (once per person per machine)              │  gh auth, SSH key, org access
├─────────────────────────────────────────────┤
│  System setup (public gist / shared mount)  │  CUDA toolkit, system libs
│  (once per machine, re-run when needed)     │  stamps ~/.cache/depfile-timestamp
├─────────────────────────────────────────────┤
│  Dotfiles (optional, personal)              │  Shell, editor, CLI tools
│  (once per machine)                         │
├─────────────────────────────────────────────┤
│  git clone + direnv allow                   │  Per project
│  .envrc: check_depfile, bazelisk, just      │  Per worktree, versioned
├─────────────────────────────────────────────┤
│  Bazel                                      │  Tools, libs, sysroots
│  (hermetic, per worktree)                   │  Everything else
└─────────────────────────────────────────────┘
```

## Key principles

- **Idempotent**: Every script can be run multiple times safely. It fixes what
  it can and reports what remains.
- **Layered dependencies**: Each layer assumes the ones above it are done.
  `.envrc` checks system setup via `check_depfile`. Bazel assumes `.envrc` ran.
- **Hermetic where possible**: Only the top layers touch the system. Bazel and
  `.envrc` keep things per-worktree and versioned.
- **System deps are forward-only**: The system setup installs CUDA 12, not CUDA
  11. Version pinning happens in Bazel sysroots where you can switch per worktree.

## Scripts

All scripts use the `intui-` prefix and kebab-case.

| Script | Purpose |
|---|---|
| `intui-setup-access` | Credentials: tools, gh auth, SSH key, org membership |
| `intui-setup-system` | System deps: CUDA, Docker, system libs (future) |
| `intui-lib.sh` | Shared helpers: `pass`, `fail`, `info`, `has`, `install_pkg` |

## The depfile check

`.envrc` in each project declares when the system setup was last required to
have been run:

```bash
check_depfile 2026-04-01 "/mnt/shared/intui-setup-system"
```

The system setup script stamps `~/.cache/depfile-timestamp` on success. direnv
compares the two dates and warns if you need to update.

## Account naming convention

`intui-<first part of email before @>` (e.g., `intui-tobias`).
