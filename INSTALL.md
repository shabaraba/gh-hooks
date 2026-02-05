# Installation Guide

Complete installation instructions for gh-hooks.

## Prerequisites

### Required

- **Supported Shell**: bash, zsh, fish, or nushell
  ```bash
  # Check your shell version
  bash --version  # Bash 4.0+
  zsh --version   # Zsh 5.0+
  fish --version  # Fish 3.0+
  nu --version    # Nushell 0.80+
  ```

- **GitHub CLI (`gh`)**
  ```bash
  # Install gh if not already installed
  # macOS
  brew install gh

  # Linux
  # See https://github.com/cli/cli/blob/trunk/docs/install_linux.md
  ```

- **Git**
  ```bash
  # Usually pre-installed
  git --version
  ```

### Optional (depending on your use case)

- **release-please** (for automated releases)
  ```bash
  npm install -g release-please
  # Or use npx (no installation required)
  ```

- **Rust toolchain** (for Rust projects)
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```

- **Node.js and npm** (for npm projects)
  ```bash
  # macOS
  brew install node

  # Linux
  # Use your package manager or visit https://nodejs.org/
  ```

## Installation Methods

### Method 1: GitHub CLI Extension (Recommended)

This is the easiest way to install and manage gh-hooks.

1. **Install the extension:**
   ```bash
   gh extension install shabaraba/gh-hooks
   ```

2. **Set up shell integration:**
   ```bash
   # Auto-detect shell from $SHELL
   gh hooks install

   # Or specify shell explicitly
   gh hooks install zsh
   gh hooks install bash
   gh hooks install fish
   gh hooks install nu
   ```

   This will:
   - Auto-detect your shell (bash, zsh, fish, or nu)
   - Add the necessary source line to your RC file
   - Create config directory and file if they don't exist

3. **Reload your shell:**
   ```bash
   exec $SHELL
   # Or manually:
   source ~/.zshrc  # or ~/.bashrc
   ```

4. **Verify installation:**
   ```bash
   gh hooks status
   ```

   You should see:
   ```
   ✓ Shell integration: ACTIVE
   ```

5. **Initialize project (optional):**
   ```bash
   cd your-project
   gh hooks init rust  # or 'node' for Node.js projects
   ```

### Method 2: Manual GitHub CLI Extension Install

If you prefer more control:

1. **Clone to extensions directory:**
   ```bash
   mkdir -p ~/.local/share/gh/extensions
   git clone https://github.com/shabaraba/gh-hooks.git \
     ~/.local/share/gh/extensions/gh-hooks
   ```

2. **Set up shell integration:**
   ```bash
   gh hooks install
   ```

3. **Reload shell:**
   ```bash
   exec $SHELL
   ```

### Method 3: Standalone Install (Legacy)

For users who don't want to use GitHub CLI extensions:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/shabaraba/gh-hooks.git ~/.gh-hooks
   ```

2. **Add to your shell configuration:**

   **For zsh (`~/.zshrc`):**
   ```bash
   echo 'source ~/.gh-hooks/gh-hooks.sh' >> ~/.zshrc
   ```

   **For bash (`~/.bashrc` or `~/.bash_profile`):**
   ```bash
   echo 'source ~/.gh-hooks/gh-hooks.sh' >> ~/.bashrc
   ```

3. **Reload your shell:**
   ```bash
   source ~/.zshrc  # or ~/.bashrc
   ```

## Shell-Specific Configuration

### Zsh

Add to `~/.zshrc`:
```bash
# gh-hooks: GitHub CLI hooks
source ~/.gh-hooks/gh-hooks.sh
```

### Bash

Add to `~/.bashrc` (Linux) or `~/.bash_profile` (macOS):
```bash
# gh-hooks: GitHub CLI hooks
source ~/.gh-hooks/gh-hooks.sh
```

### Fish Shell

Add to `~/.config/fish/config.fish`:
```fish
# gh-hooks: GitHub CLI hooks
source ~/.gh-hooks/gh-hooks.fish
```

**Note:** Fish shell integration is added but `gh-hooks.fish` will be available in a future version.

### Nushell

Add to `~/.config/nushell/config.nu`:
```nu
# gh-hooks: GitHub CLI hooks
source ~/.gh-hooks/gh-hooks.nu
```

**Note:** Nushell integration is added but `gh-hooks.nu` will be available in a future version.

## Project Setup

After installing gh-hooks globally, set up each project:

### Quick Setup with Templates

**For Rust projects:**
```bash
cd your-project
gh hooks init rust
```

**For Node.js/npm projects:**
```bash
cd your-project
gh hooks init node
```

This creates a `.gh-hooks.sh` with pre-configured hooks for your project type.

### Manual Setup

If you prefer to create `.gh-hooks.sh` manually:

```bash
cd your-project
touch .gh-hooks.sh
chmod +x .gh-hooks.sh
```

### 2. Choose a Template

Copy an example template:

**For Rust projects:**
```bash
cp ~/.gh-hooks/examples/rust-crates.sh .gh-hooks.sh
```

**For npm projects:**
```bash
cp ~/.gh-hooks/examples/npm-publish.sh .gh-hooks.sh
```

**Or create from scratch:**
```bash
cat > .gh-hooks.sh << 'EOF'
#!/bin/bash

# Hook: PR merged
gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"
  echo "PR #${pr_number} merged: ${pr_title}"
  # Your custom logic here
}

# Hook: Release PR merged
gh_hook_release_pr_merged() {
  local version="$1"
  echo "Release ${version}"
  # Your custom logic here
}
EOF
```

### 3. Set Environment Variables

For automated releases, set `GITHUB_TOKEN`:

```bash
# Add to ~/.zshrc or ~/.bashrc
export GITHUB_TOKEN="your_github_token_here"
```

To create a token:
1. Go to https://github.com/settings/tokens
2. Generate new token (classic)
3. Select scopes: `repo`, `workflow`
4. Copy the token and add to your shell config

### 4. Test

```bash
# Enable debug mode
export GH_HOOKS_DEBUG=1

# Test with a PR merge
gh pr merge 123 --squash

# Check status
gh hooks status
```

## Updating gh-hooks

### Update Extension

```bash
# Update to latest version
gh extension upgrade hooks

# Or update all extensions
gh extension upgrade --all
```

### Update Manually

```bash
cd ~/.local/share/gh/extensions/gh-hooks
git pull origin main
```

### Update Project Config

If the hook API changes, you may need to update your `.gh-hooks.sh`:

```bash
# Backup your current config
cp .gh-hooks.sh .gh-hooks.sh.backup

# Re-generate from template
gh hooks init rust  # or 'node'

# Manually merge your customizations
```

## Uninstallation

### Using Extension Commands (Recommended)

```bash
# Remove shell integration
gh hooks uninstall

# Remove the extension
gh extension remove hooks
```

### Manual Uninstallation

```bash
# Remove shell integration lines from RC file
# (gh hooks uninstall creates a backup automatically)

# Remove extension
rm -rf ~/.local/share/gh/extensions/gh-hooks

# For standalone install
rm -rf ~/.gh-hooks
```

### Remove Project Config

```bash
cd your-project
rm .gh-hooks.sh
```

## Troubleshooting

### Issue: Command Not Found

**Symptom:** `gh_hooks_status: command not found`

**Solution:**
1. Verify gh-hooks.sh is sourced in your shell config
2. Restart your shell: `source ~/.zshrc`
3. Check if file exists: `ls -la ~/.gh-hooks/gh-hooks.sh`

### Issue: Hooks Not Running

**Symptom:** `gh pr merge` works but hooks don't trigger

**Solutions:**
1. Check if you're in a git repository
2. Verify `.gh-hooks.sh` exists in project root
3. Enable debug mode: `export GH_HOOKS_DEBUG=1`
4. Check syntax: `bash -n .gh-hooks.sh`
5. Verify hooks are enabled: `gh_hooks_status`

### Issue: Permission Denied

**Symptom:** `permission denied` when running scripts

**Solution:**
```bash
chmod +x ~/.gh-hooks/gh-hooks.sh
chmod +x .gh-hooks.sh
```

### Issue: Infinite Loop

**Symptom:** Hook keeps calling itself

**Solution:**
Don't call `gh` commands inside hooks without precautions. The system has built-in infinite loop detection, but it's better to avoid it:

```bash
# BAD: This will cause infinite loop
gh_hook_pr_merged() {
  gh pr list  # Don't do this!
}

# GOOD: Use command directly
gh_hook_pr_merged() {
  command gh pr list  # This is safe
}
```

### Issue: Syntax Error in Config

**Symptom:** `Failed to load .gh-hooks.sh: syntax error`

**Solution:**
```bash
# Test your config
bash -n .gh-hooks.sh

# Common issues:
# - Missing quotes
# - Unmatched brackets
# - Invalid function syntax
```

## Advanced Configuration

### Using with dotfiles

If you manage dotfiles with git:

```bash
cd ~/dotfiles
git submodule add https://github.com/yourusername/gh-hooks.git gh-hooks

# In your shell config
source ~/dotfiles/gh-hooks/gh-hooks.sh
```

### Project-Local Installation

For projects that want a specific version:

```bash
cd your-project
git submodule add https://github.com/yourusername/gh-hooks.git .gh-hooks-lib

# In .gh-hooks.sh
source "$(dirname "$0")/.gh-hooks-lib/gh-hooks.sh"

# Then define your hooks...
```

### Custom Installation Directory

```bash
# Install to custom location
INSTALL_DIR=/opt/gh-hooks ./install.sh

# Update shell config
source /opt/gh-hooks/gh-hooks.sh
```

## Next Steps

1. Read [README.md](README.md) for usage examples
2. Browse [examples/](examples/) for templates
3. Check [docs/API.md](docs/API.md) for complete API reference
4. See [docs/CUSTOM_HOOKS.md](docs/CUSTOM_HOOKS.md) for advanced hooks

## Getting Help

- Check [Troubleshooting](#troubleshooting) section above
- Enable debug mode: `export GH_HOOKS_DEBUG=1`
- Run `gh_hooks_status` to check configuration
- Open an issue on GitHub
