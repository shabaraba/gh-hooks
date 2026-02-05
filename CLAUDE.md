# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

gh-hooks is a GitHub CLI extension that adds hook functionality to `gh` commands. It allows users to automatically execute custom scripts after certain GitHub operations (PR merge, PR create, release create, etc.), enabling local CI/CD workflows.

**Core Concept**: Wraps the `gh` command in shell functions (bash/zsh) to intercept successful command executions and trigger user-defined hooks from `.gh-hooks.sh` files in project roots.

## Architecture

### Components

1. **gh-hooks (Extension Entry Point)** - `gh-hooks`
   - Bash script that serves as the GitHub CLI extension
   - Handles subcommands: `install`, `uninstall`, `status`, `init`, `enable`, `disable`
   - Sources utility functions from `lib/utils.sh`

2. **Shell Integration** - `gh-hooks.sh`
   - Defines the `gh()` wrapper function
   - Lazy initialization on first `gh` command use
   - Sources core modules from `lib/`
   - Exports helper functions: `gh_disable_hooks`, `gh_enable_hooks`, `gh_hooks_status`, `gh_hooks_help`

3. **Core Modules** - `lib/`
   - `lib/core.sh`: Project root detection, config loading, command dispatching
   - `lib/hooks.sh`: Hook execution engine, release PR detection, version extraction
   - `lib/utils.sh`: Utility functions for logging, command checks

4. **Project Configuration** - `.gh-hooks.sh`
   - User-defined hook functions in project root
   - Sourced dynamically when in a git repository

### Hook Execution Flow

```
User runs: gh pr merge 123
  ↓
gh() wrapper function (gh-hooks.sh)
  ↓
command gh pr merge 123  [actual gh CLI execution]
  ↓ (if successful and hooks enabled)
_gh_hooks_dispatch() (lib/core.sh)
  ↓
_gh_hooks_load_config()  [loads .gh-hooks.sh from project root]
  ↓
_gh_hooks_handle_pr_merge() (lib/hooks.sh)
  ↓
[Detects if release PR, extracts version if needed]
  ↓
_gh_hooks_call() → gh_hook_pr_merged() or gh_hook_release_pr_merged()
```

### Key Design Patterns

- **Lazy Initialization**: Commands/dependencies checked on first use, not at shell startup (avoids startup errors)
- **Infinite Loop Prevention**: `_GH_HOOKS_IN_EXECUTION` flag prevents hooks from triggering nested hooks
- **Release PR Detection**: Uses regex pattern matching on PR titles + version extraction from CHANGELOG.md/Cargo.toml/package.json
- **Project-Scoped Config**: Each git repository can have its own `.gh-hooks.sh` with custom hooks

## Development Commands

### Testing

This project uses its own hooks for release automation. Test hooks in a separate test repository to avoid accidental releases.

```bash
# Test shell integration in current shell
source ./gh-hooks.sh
gh_hooks_status

# Test extension commands (requires installation as gh extension)
gh hooks status
gh hooks init rust  # Creates .gh-hooks.sh template

# Debug mode - see hook execution details
export GH_HOOKS_DEBUG=1
gh pr merge <number>
```

### Shell Compatibility Testing

Test across different shells:

```bash
# bash
bash -c "source ./gh-hooks.sh && gh_hooks_status"

# zsh
zsh -c "source ./gh-hooks.sh && gh_hooks_status"

# fish (requires gh-hooks.fish, currently unsupported)
# nu (requires gh-hooks.nu, currently unsupported)
```

### Installation Testing

```bash
# Install as gh extension (requires gh CLI)
gh extension install .

# Test installation
gh hooks install zsh
gh hooks status

# Uninstall
gh hooks uninstall
```

## Release Process

This project uses **release-please** for automated releases via gh-hooks itself (see `.gh-hooks.sh` and `HOOKS_SETUP.md`).

### Manual Release Steps

1. Merge feature PRs with semantic commit messages (feat:, fix:, etc.)
2. PR merge triggers `gh_hook_pr_merged` → runs `release-please release-pr`
3. Release PR is auto-created/updated with version bump and CHANGELOG
4. Merge release PR triggers `gh_hook_release_pr_merged` → runs `release-please github-release`
5. GitHub release is automatically created with tag

### Required Environment

- **GITHUB_TOKEN**: Personal access token with `repo` and `workflow` scopes
- **Node.js/npx**: For running `release-please` commands

## Code Conventions

### Shell Scripting

- **ShellCheck**: All scripts should pass shellcheck validation
- **Function Naming**:
  - Internal functions: `_gh_hooks_*` (prefixed with underscore)
  - Hook functions: `gh_hook_*` (defined by users)
  - Utility functions: `gh_hooks_*` or `gh_*` (exposed to users)
- **Error Handling**: Use `set -e` in scripts; check exit codes explicitly in functions
- **Logging**: Use `_gh_hooks_debug`, `_gh_hooks_info`, `_gh_hooks_warn`, `_gh_hooks_error` from lib/utils.sh

### File Structure

- Extension entry: `gh-hooks` (executable, no extension)
- Shell integration: `gh-hooks.sh` (bash/zsh), future: `gh-hooks.fish`, `gh-hooks.nu`
- Libraries: `lib/*.sh`
- Examples: `examples/*.sh`
- Documentation: `README.md`, `INSTALL.md`, `HOOKS_SETUP.md`, `docs/*.md`

## Important Constraints

1. **No Startup Overhead**: Shell integration must load fast (<10ms impact)
2. **Lazy Initialization**: Don't check for `gh` or `git` at source time - only on first use
3. **Backward Compatibility**: Changes to hook signatures require major version bump
4. **Cross-Shell Support**: Primary support for bash/zsh; fish/nushell are future goals
5. **Security**: Config files should not be world-writable (checked at load time)

## Common Pitfalls

- **Infinite Loops**: Always set `_GH_HOOKS_IN_EXECUTION=1` before calling user hooks
- **Symlink Handling**: RC files may be symlinks; use `readlink` to resolve before editing
- **Platform Differences**: macOS uses `.bash_profile`, Linux uses `.profile`
- **Version Extraction**: Support multiple sources (CHANGELOG, Cargo.toml, package.json) with fallback
- **Shell Differences**: bash requires `export -f` for functions; zsh does not

## Testing Strategy

- **Manual Testing**: Primary testing method - install extension and test with real `gh` commands
- **Shell Script Validation**: Use `bash -n` or `shellcheck` for syntax/style checks
- **Integration Testing**: Test in actual git repositories with PRs
- **Multi-Shell Testing**: Verify in bash and zsh environments

## Related Documentation

- `README.md`: User-facing quick start and feature overview
- `INSTALL.md`: Detailed installation instructions
- `HOOKS_SETUP.md`: This project's own hooks configuration (dogfooding example)
- `docs/API.md`: Complete hook API reference (if exists)
- `docs/CUSTOM_HOOKS.md`: Guide for writing custom hooks (if exists)
