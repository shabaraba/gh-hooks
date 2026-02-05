# API Reference

Complete API documentation for gh-hooks.

## Hook Functions

All hook functions are optional. Define them in your project's `.gh-hooks.sh` file.

### gh_hook_pr_merged

Called after a pull request is successfully merged.

**Signature:**
```bash
gh_hook_pr_merged <pr_title> <pr_number>
```

**Parameters:**
- `pr_title` (string): Title of the merged PR
- `pr_number` (integer): PR number

**Return Value:**
- `0`: Success
- Non-zero: Error (logged but doesn't affect gh command)

**Example:**
```bash
gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  echo "PR #${pr_number} merged: ${pr_title}"

  # Run release-please
  npx release-please release-pr \
    --token="${GITHUB_TOKEN}" \
    --repo-url="$(git config remote.origin.url)" \
    --release-type=rust
}
```

**Triggered by:**
- `gh pr merge <number>`
- `gh pr merge <number> --squash`
- `gh pr merge <number> --merge`
- `gh pr merge <number> --rebase`

---

### gh_hook_release_pr_merged

Called after a release PR is successfully merged. A release PR is detected by matching the title against `GH_HOOKS_RELEASE_PATTERN` (default: `^chore\(main\): release`).

**Signature:**
```bash
gh_hook_release_pr_merged <version>
```

**Parameters:**
- `version` (string): Extracted version number (e.g., "1.2.3")

**Return Value:**
- `0`: Success
- Non-zero: Error (logged but doesn't affect gh command)

**Example:**
```bash
gh_hook_release_pr_merged() {
  local version="$1"

  echo "Release ${version}"

  # Publish to crates.io
  cargo publish

  # Create GitHub release
  gh release create "v${version}" \
    --title "v${version}" \
    --notes-file CHANGELOG.md
}
```

**Version Extraction:**
Version is extracted in this order:
1. `CHANGELOG.md` - First `## [x.y.z]` entry
2. `Cargo.toml` - `version = "x.y.z"`
3. `package.json` - `"version": "x.y.z"`

**Triggered by:**
- `gh pr merge <number>` where PR title matches release pattern

---

### gh_hook_pr_created

Called after a pull request is successfully created.

**Signature:**
```bash
gh_hook_pr_created <pr_number> <pr_url>
```

**Parameters:**
- `pr_number` (integer): Created PR number
- `pr_url` (string): Full URL to the PR

**Return Value:**
- `0`: Success
- Non-zero: Error (logged but doesn't affect gh command)

**Example:**
```bash
gh_hook_pr_created() {
  local pr_number="$1"
  local pr_url="$2"

  echo "Created PR #${pr_number}: ${pr_url}"

  # Send notification
  curl -X POST "$SLACK_WEBHOOK" \
    -d "{\"text\": \"New PR: ${pr_url}\"}"
}
```

**Triggered by:**
- `gh pr create`
- `gh pr create --fill`
- `gh pr create --title "..." --body "..."`

---

### gh_hook_pr_closed

Called after a pull request is closed without merging.

**Signature:**
```bash
gh_hook_pr_closed <pr_number>
```

**Parameters:**
- `pr_number` (integer): Closed PR number

**Return Value:**
- `0`: Success
- Non-zero: Error (logged but doesn't affect gh command)

**Example:**
```bash
gh_hook_pr_closed() {
  local pr_number="$1"

  echo "PR #${pr_number} closed without merging"

  # Clean up resources
  rm -rf "pr-${pr_number}-temp"
}
```

**Triggered by:**
- `gh pr close <number>`

---

### gh_hook_release_created

Called after a GitHub release is created.

**Signature:**
```bash
gh_hook_release_created <tag_name> <release_url>
```

**Parameters:**
- `tag_name` (string): Git tag name (e.g., "v1.2.3")
- `release_url` (string): Full URL to the release

**Return Value:**
- `0`: Success
- Non-zero: Error (logged but doesn't affect gh command)

**Example:**
```bash
gh_hook_release_created() {
  local tag_name="$1"
  local release_url="$2"

  echo "Release created: ${tag_name}"

  # Trigger deployment
  ./deploy.sh "$tag_name"
}
```

**Triggered by:**
- `gh release create <tag>`

---

## Environment Variables

### GH_HOOKS_ENABLED

Enable or disable hooks globally.

**Type:** Integer (0 or 1)
**Default:** `1` (enabled)

**Usage:**
```bash
# Disable hooks
export GH_HOOKS_ENABLED=0

# Re-enable hooks
export GH_HOOKS_ENABLED=1

# Or use helper functions
gh_disable_hooks
gh_enable_hooks
```

---

### GH_HOOKS_DEBUG

Enable debug logging.

**Type:** Integer (0 or 1)
**Default:** `0` (disabled)

**Usage:**
```bash
# Enable debug mode
export GH_HOOKS_DEBUG=1

# Run a command
gh pr merge 123

# Disable debug mode
export GH_HOOKS_DEBUG=0
```

**Debug Output:**
```
[gh-hooks debug] Dispatching: gh pr merge 123 --squash
[gh-hooks debug] Project root found: /Users/you/project
[gh-hooks debug] Loading config from: /Users/you/project/.gh-hooks.sh
[gh-hooks debug] Config loaded successfully
[gh-hooks debug] PR #123: feat: add new feature
[gh-hooks debug] Calling hook: gh_hook_pr_merged feat: add new feature 123
```

---

### GH_HOOKS_RELEASE_PATTERN

Regular expression to detect release PRs.

**Type:** String (bash regex)
**Default:** `^chore\(main\): release`

**Usage:**
```bash
# In .gh-hooks.sh or shell config
export GH_HOOKS_RELEASE_PATTERN="^chore\(main\): release"

# Or custom pattern
export GH_HOOKS_RELEASE_PATTERN="^Release v"
```

**Examples:**
- `^chore\(main\): release` → Matches "chore(main): release 1.2.3"
- `^Release v` → Matches "Release v1.2.3"
- `^chore: release` → Matches "chore: release 1.2.3"

---

## Utility Functions

These functions are available within hook functions.

### _gh_hooks_get_repo_slug

Get the repository slug (owner/repo) from git config.

**Signature:**
```bash
_gh_hooks_get_repo_slug
```

**Return Value:**
- String: "owner/repo" on success
- Empty string and exit code 1 on failure

**Example:**
```bash
gh_hook_pr_merged() {
  local repo_slug=$(_gh_hooks_get_repo_slug)
  echo "Repository: ${repo_slug}"
}
```

---

### _gh_hooks_debug

Log a debug message (only shown when `GH_HOOKS_DEBUG=1`).

**Signature:**
```bash
_gh_hooks_debug <message>
```

**Example:**
```bash
gh_hook_pr_merged() {
  _gh_hooks_debug "Starting PR merge hook"
  # Your logic here
}
```

---

### _gh_hooks_info

Log an info message (always shown).

**Signature:**
```bash
_gh_hooks_info <message>
```

**Example:**
```bash
gh_hook_pr_merged() {
  _gh_hooks_info "Running release-please..."
  npx release-please ...
}
```

---

### _gh_hooks_warn

Log a warning message.

**Signature:**
```bash
_gh_hooks_warn <message>
```

**Example:**
```bash
gh_hook_pr_merged() {
  if [ -z "$GITHUB_TOKEN" ]; then
    _gh_hooks_warn "GITHUB_TOKEN not set, skipping release-please"
    return 0
  fi
}
```

---

### _gh_hooks_error

Log an error message.

**Signature:**
```bash
_gh_hooks_error <message>
```

**Example:**
```bash
gh_hook_release_pr_merged() {
  if ! cargo publish; then
    _gh_hooks_error "Failed to publish to crates.io"
    return 1
  fi
}
```

---

### _gh_hooks_run_release_please

Run release-please to create or update release PR.

**Signature:**
```bash
_gh_hooks_run_release_please <release_type>
```

**Parameters:**
- `release_type` (string): Project type (e.g., "rust", "node", "python")

**Return Value:**
- `0`: Always returns success (errors are logged but don't fail)

**Example:**
```bash
gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  echo "PR #${pr_number} merged"
  _gh_hooks_run_release_please rust
}
```

**Requirements:**
- `GITHUB_TOKEN` environment variable must be set
- `npx` and `release-please` must be available

---

### _gh_hooks_create_github_release

Create GitHub release with optional CHANGELOG notes.

**Signature:**
```bash
_gh_hooks_create_github_release <version>
```

**Parameters:**
- `version` (string): Version number (e.g., "1.2.3")

**Return Value:**
- `0`: Release created successfully
- `1`: Release creation failed

**Example:**
```bash
gh_hook_release_pr_merged() {
  local version="$1"

  echo "Publishing version ${version}"
  cargo publish

  _gh_hooks_create_github_release "$version"
}
```

**Behavior:**
- Uses `CHANGELOG.md` if present, otherwise generates notes automatically
- Creates release with tag `v${version}`

---

## Command Functions

### gh_hooks_status

Show current gh-hooks status and configuration.

**Usage:**
```bash
gh_hooks_status
```

**Output:**
```
gh-hooks status:
  Version: 0.1.0
  Enabled: 1
  Debug: 0
  Install directory: /Users/you/.gh-hooks
  Project root: /Users/you/project
  Config file: /Users/you/project/.gh-hooks.sh (found)
  Defined hooks:
    - gh_hook_pr_merged
    - gh_hook_release_pr_merged
```

---

### gh_disable_hooks

Temporarily disable hooks.

**Usage:**
```bash
gh_disable_hooks
```

**Effect:**
Sets `GH_HOOKS_ENABLED=0` and displays a message.

---

### gh_enable_hooks

Re-enable hooks.

**Usage:**
```bash
gh_enable_hooks
```

**Effect:**
Sets `GH_HOOKS_ENABLED=1` and displays a message.

---

### gh_hooks_help

Show help message.

**Usage:**
```bash
gh_hooks_help
```

---

## Best Practices

### Error Handling

Always handle errors gracefully:

```bash
gh_hook_release_pr_merged() {
  local version="$1"

  # Check prerequisites
  if [ -z "$GITHUB_TOKEN" ]; then
    _gh_hooks_warn "GITHUB_TOKEN not set"
    return 0  # Return success to not fail the gh command
  fi

  # Run command with error handling
  if cargo publish; then
    _gh_hooks_info "Published to crates.io"
  else
    _gh_hooks_error "Failed to publish (exit code: $?)"
    # Return 0 to not affect gh command success
    return 0
  fi
}
```

### Avoid Infinite Loops

Don't call `gh` commands in hooks without using `command`:

```bash
# BAD: Will cause infinite loop
gh_hook_pr_merged() {
  gh pr list  # This calls the wrapper, triggering hooks again
}

# GOOD: Use command to bypass wrapper
gh_hook_pr_merged() {
  command gh pr list  # This calls gh directly
}
```

The system has built-in infinite loop detection, but it's better to avoid the situation.

### Conditional Execution

Only run hooks when conditions are met:

```bash
gh_hook_pr_merged() {
  local pr_title="$1"

  # Skip if this is a draft PR
  if [[ "$pr_title" == *"[Draft]"* ]]; then
    _gh_hooks_debug "Skipping draft PR"
    return 0
  fi

  # Your logic here
}
```

### Logging

Use appropriate log levels:

```bash
gh_hook_pr_merged() {
  _gh_hooks_debug "Starting hook"  # Only shown in debug mode
  _gh_hooks_info "Running process"  # Always shown
  _gh_hooks_warn "Optional dependency missing"  # Warning
  _gh_hooks_error "Critical failure"  # Error
}
```

## Version

API Version: 0.1.0
Last Updated: 2026-02-05
