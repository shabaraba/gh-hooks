# gh-hooks

GitHub CLI hooks system - Automate workflows after `gh` commands


[![GitHub](https://img.shields.io/badge/GitHub-shabaraba%2Fgh--hooks-blue)](https://github.com/shabaraba/gh-hooks)


## Installation

```bash
# Install as GitHub CLI extension
gh extension install shabaraba/gh-hooks

# Set up shell integration (auto-detects your shell)
gh hooks install

# Or specify shell explicitly (bash, zsh, fish, nu)
gh hooks install zsh

# Reload your shell
exec $SHELL
```

**Supported shells:** bash, zsh, fish, nushell (nu)

### Installation Locations

The installer adds hooks to **both RC and profile files** for comprehensive coverage:

**For zsh:**
- `~/.zshrc` - Loaded for interactive shells
- `~/.zprofile` - Loaded for login shells and non-interactive contexts

**For bash:**
- `~/.bashrc` - Loaded for interactive shells
- `~/.bash_profile` (macOS) or `~/.profile` (Linux) - Loaded for login shells

**Why both files?**

Non-interactive tools (like Claude Code's Bash tool, CI/CD scripts, or automated processes) typically only load profile files (`.zprofile`, `.bash_profile`), not RC files (`.zshrc`, `.bashrc`). Installing to both locations ensures gh-hooks works in all contexts:

- ✅ Interactive terminal sessions (`.zshrc`, `.bashrc`)
- ✅ Non-interactive shells (`.zprofile`, `.bash_profile`)
- ✅ Editor integrated terminals (Claude Code, VSCode, etc.)
- ✅ Automated scripts and CI/CD pipelines

Without profile file installation, hooks would not work in non-interactive contexts, limiting automation capabilities.

## Overview

`gh-hooks` adds powerful hook functionality to GitHub CLI (`gh` command), allowing you to automatically execute custom scripts after certain GitHub operations. This enables local CI/CD workflows without relying on GitHub Actions minutes.

### Key Features

- 🎯 **Automatic Hook Execution**: Hooks trigger after successful `gh` commands
- 📦 **Project-Specific Config**: Each project can have its own `.gh-hooks.sh`
- 🔧 **Flexible**: Supports PR merge, creation, close, and release events
- ⚡ **Minimal Overhead**: <10ms overhead per `gh` command
- 🚫 **Easy to Disable**: Set `GH_HOOKS_ENABLED=0` to temporarily disable

### Use Cases

#### Rust Projects
- Auto-run `release-please` when PR is merged
- Auto-publish to crates.io when release PR is merged
- Create GitHub releases automatically

#### npm Projects
- Auto-run `release-please` when PR is merged
- Auto-publish to npm when release PR is merged
- Create GitHub releases automatically

#### Any Project
- Send notifications to Slack/Discord
- Trigger local builds
- Update documentation
- Run custom automation scripts

## Quick Start

### 1. Install as GitHub CLI Extension (Recommended)

```bash
# Install the extension
gh extension install shabaraba/gh-hooks

# Set up shell integration (auto-detects from $SHELL)
gh hooks install

# Or specify your shell (bash, zsh, fish, nu)
gh hooks install zsh

# Reload your shell
exec $SHELL
```

### 2. Initialize Project Configuration

In your project root:

```bash
# For Rust projects
gh hooks init rust

# For Node.js/npm projects
gh hooks init node
```

This creates a `.gh-hooks.sh` with example hooks.

### 3. Customize `.gh-hooks.sh`

Edit the generated `.gh-hooks.sh` in your project root:

```bash
#!/bin/bash

# Hook: Called after PR merge
gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  echo "PR #${pr_number} merged: ${pr_title}"
  # Your automation here
}

# Hook: Called after release PR merge
gh_hook_release_pr_merged() {
  local version="$1"

  echo "Release ${version}"
  # Auto-publish, create release, etc.
}
```

### 4. Use GitHub CLI Normally

```bash
# Merge a PR - hooks will trigger automatically
gh pr merge 123 --squash

# Create a PR - gh_hook_pr_created will be called
gh pr create --fill
```

## Available Hooks

| Hook Function | When Called | Parameters | Execution Mode |
|---------------|-------------|------------|----------------|
| `gh_hook_pr_merged` | After `gh pr merge` | `<pr_title>` `<pr_number>` | Synchronous |
| `gh_hook_pr_merged_async` | After `gh pr merge` | `<pr_title>` `<pr_number>` | Asynchronous |
| `gh_hook_release_pr_merged` | After merging a release PR | `<version>` | Synchronous |
| `gh_hook_release_pr_merged_async` | After merging a release PR | `<version>` | Asynchronous |
| `gh_hook_pr_created` | After `gh pr create` | `<pr_number>` `<pr_url>` | Synchronous |
| `gh_hook_pr_created_async` | After `gh pr create` | `<pr_number>` `<pr_url>` | Asynchronous |
| `gh_hook_pr_closed` | After `gh pr close` | `<pr_number>` | Synchronous |
| `gh_hook_pr_closed_async` | After `gh pr close` | `<pr_number>` | Asynchronous |
| `gh_hook_release_created` | After `gh release create` | `<tag_name>` `<release_url>` | Synchronous |
| `gh_hook_release_created_async` | After `gh release create` | `<tag_name>` `<release_url>` | Asynchronous |

### Synchronous vs Asynchronous Hooks

- **Synchronous hooks**: Block the `gh` command until completion. Use for critical operations that must complete before continuing.
- **Asynchronous hooks** (with `_async` suffix): Run in the background without blocking. The `gh` command returns immediately.

**When to use async hooks:**
- Long-running operations (publishing packages, sending notifications)
- Non-critical tasks that can fail without affecting the workflow
- Operations that don't need to complete before the next command

**Using both versions together:**
If both `gh_hook_name` and `gh_hook_name_async` are defined:
1. The `_async` version starts first in the background (non-blocking)
2. The sync version runs immediately after (blocking)
3. Both hooks execute, allowing parallel long-running tasks with sequential critical operations

Example use case:
```bash
# Async: Start long-running package publish in background
gh_hook_release_pr_merged_async() {
  cargo publish  # Runs in background
}

# Sync: Perform critical local operations
gh_hook_release_pr_merged() {
  gh release create "v$1"  # Waits for completion
}
```

## Examples

See the `examples/` directory for complete templates:

### Rust Project (`examples/rust-crates.sh`)

```bash
gh_hook_pr_merged() {
  npx release-please release-pr \
    --token="${GITHUB_TOKEN}" \
    --repo-url="owner/repo" \
    --release-type=rust
}

gh_hook_release_pr_merged() {
  cargo publish
  gh release create "v${1}" --notes-file CHANGELOG.md
}
```

### npm Project (`examples/npm-publish.sh`)

```bash
gh_hook_pr_merged() {
  npx release-please release-pr \
    --token="${GITHUB_TOKEN}" \
    --repo-url="owner/repo" \
    --release-type=node
}

gh_hook_release_pr_merged() {
  npm publish
  gh release create "v${1}" --notes-file CHANGELOG.md
}
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GH_HOOKS_ENABLED` | `1` | Enable/disable hooks (0=off, 1=on) |
| `GH_HOOKS_DEBUG` | `0` | Debug mode (0=off, 1=on) |
| `GH_HOOKS_RELEASE_PATTERN` | `^chore\(main\): release` | Pattern to detect release PRs |

### Extension Commands

```bash
# Show current status
gh hooks status

# Initialize project configuration
gh hooks init rust       # For Rust projects
gh hooks init node       # For Node.js projects

# Temporarily disable hooks
gh hooks disable

# Re-enable hooks
gh hooks enable

# Uninstall shell integration
gh hooks uninstall

# Show help
gh hooks help
```

### Legacy Shell Commands (still available)

```bash
# These commands are also available for direct use
gh_hooks_status
gh_disable_hooks
gh_enable_hooks
gh_hooks_help
```

## How It Works

1. `gh-hooks.sh` defines a `gh()` wrapper function
2. The wrapper calls the real `gh` command
3. If successful, it triggers the appropriate hook from your `.gh-hooks.sh`
4. Your hook function runs with relevant parameters

### Release PR Detection

gh-hooks automatically detects release PRs by matching the title against `GH_HOOKS_RELEASE_PATTERN`. When a release PR is detected:

1. Version is extracted from `CHANGELOG.md`, `Cargo.toml`, or `package.json`
2. `gh_hook_release_pr_merged` is called instead of `gh_hook_pr_merged`

## Requirements

- **Required**: bash 4.0+ or zsh 5.0+, `gh` CLI, `git`
- **Optional**: `release-please`, `cargo`/`npm` (depending on your project)

## Installation Locations

### Global Install (Recommended)
```
~/.gh-hooks/           # Installed library
  ├── gh-hooks.sh      # Main script
  ├── lib/             # Core modules
  └── examples/        # Templates

~/.zshrc or ~/.bashrc  # Source gh-hooks.sh from here
```

### Project Config
```
your-project/
  └── .gh-hooks.sh     # Project-specific hooks
```

## Troubleshooting

### Hooks Not Running

1. Check if hooks are enabled:
   ```bash
   gh hooks status
   ```

2. Verify shell integration:
   ```bash
   type gh | grep function
   # Should show "gh is a function"
   ```

3. Enable debug mode:
   ```bash
   export GH_HOOKS_DEBUG=1
   gh pr merge 123
   ```

4. Verify `.gh-hooks.sh` exists in your project root:
   ```bash
   ls -la .gh-hooks.sh
   ```

### Syntax Errors in `.gh-hooks.sh`

Test your config file:
```bash
bash -n .gh-hooks.sh
```

## This Project's Hooks Setup

このプロジェクト自体もgh-hooksを使用してリリースプロセスを自動化しています。

- **設定ファイル**: [`.gh-hooks.sh`](.gh-hooks.sh)
- **詳細ドキュメント**: [HOOKS_SETUP.md](HOOKS_SETUP.md)

### リリースフロー

1. PRマージ → release-pleaseが自動実行 → リリースPR作成
2. リリースPRマージ → GitHubリリースが自動作成

詳細は[HOOKS_SETUP.md](HOOKS_SETUP.md)を参照してください。

## Documentation

- [INSTALL.md](INSTALL.md) - Detailed installation guide
- [HOOKS_SETUP.md](HOOKS_SETUP.md) - This project's hooks configuration
- [docs/API.md](docs/API.md) - Complete API reference
- [docs/CUSTOM_HOOKS.md](docs/CUSTOM_HOOKS.md) - Writing custom hooks

## License

MIT License - See [LICENSE](LICENSE) file for details

## Contributing

Contributions welcome! Please open an issue or PR.
