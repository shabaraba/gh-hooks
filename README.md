# gh-hooks

GitHub CLI hooks system - Automate workflows after `gh` commands

## Overview

`gh-hooks` adds hook functionality to GitHub CLI (`gh` command), allowing you to automatically execute custom scripts after certain GitHub operations. This enables local CI/CD workflows without relying on GitHub Actions minutes.

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

### 1. Install

```bash
cd gh-hooks
./install.sh
```

This will:
- Copy files to `~/.gh-hooks/`
- Add `source ~/.gh-hooks/gh-hooks.sh` to your shell config (`.zshrc` or `.bashrc`)

### 2. Restart Your Shell

```bash
# Reload your shell configuration
source ~/.zshrc  # or ~/.bashrc
```

### 3. Create Project Configuration

In your project root, create `.gh-hooks.sh`:

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

| Hook Function | When Called | Parameters |
|---------------|-------------|------------|
| `gh_hook_pr_merged` | After `gh pr merge` | `<pr_title>` `<pr_number>` |
| `gh_hook_release_pr_merged` | After merging a release PR | `<version>` |
| `gh_hook_pr_created` | After `gh pr create` | `<pr_number>` `<pr_url>` |
| `gh_hook_pr_closed` | After `gh pr close` | `<pr_number>` |
| `gh_hook_release_created` | After `gh release create` | `<tag_name>` `<release_url>` |

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

### Commands

```bash
# Show current status
gh_hooks_status

# Temporarily disable hooks
gh_disable_hooks

# Re-enable hooks
gh_enable_hooks

# Show help
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
   gh_hooks_status
   ```

2. Enable debug mode:
   ```bash
   export GH_HOOKS_DEBUG=1
   gh pr merge 123
   ```

3. Verify `.gh-hooks.sh` exists in your project root:
   ```bash
   ls -la .gh-hooks.sh
   ```

### Syntax Errors in `.gh-hooks.sh`

Test your config file:
```bash
bash -n .gh-hooks.sh
```

## Documentation

- [INSTALL.md](INSTALL.md) - Detailed installation guide
- [docs/API.md](docs/API.md) - Complete API reference
- [docs/CUSTOM_HOOKS.md](docs/CUSTOM_HOOKS.md) - Writing custom hooks

## License

MIT License - See [LICENSE](LICENSE) file for details

## Contributing

Contributions welcome! Please open an issue or PR.

## Version

0.1.0 (MVP)
