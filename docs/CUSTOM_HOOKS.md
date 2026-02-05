# Writing Custom Hooks

Guide to creating custom hooks for gh-hooks.

## Table of Contents

1. [Basic Hook Structure](#basic-hook-structure)
2. [Synchronous vs Asynchronous Hooks](#synchronous-vs-asynchronous-hooks)
3. [Hook Function Signatures](#hook-function-signatures)
4. [Common Patterns](#common-patterns)
5. [Advanced Techniques](#advanced-techniques)
6. [Testing Hooks](#testing-hooks)
7. [Examples](#examples)

## Basic Hook Structure

A `.gh-hooks.sh` file is a bash script that defines hook functions.

### Minimal Example

```bash
#!/bin/bash

# Hook: PR merged
gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  echo "PR #${pr_number} merged: ${pr_title}"
}
```

### With Configuration

```bash
#!/bin/bash

# Configuration
export GH_HOOKS_RELEASE_PATTERN="^chore\(main\): release"
export GH_HOOKS_DEBUG=0

# Helper function (not a hook)
send_slack_notification() {
  local message="$1"
  curl -X POST "$SLACK_WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{\"text\": \"${message}\"}"
}

# Hook: PR merged
gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  send_slack_notification "PR #${pr_number} merged: ${pr_title}"
}
```

## Synchronous vs Asynchronous Hooks

gh-hooks supports two execution modes for hooks:

### Synchronous Hooks (Default)

Synchronous hooks block the `gh` command until completion.

```bash
gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  echo "Processing PR #${pr_number}..."
  # This blocks until complete
  sleep 5
  echo "Done!"
}
```

**Use when:**
- Critical operations that must complete before continuing
- Operations that affect the next command (e.g., git operations)
- Fast operations (< 1 second)

### Asynchronous Hooks (Add `_async` suffix)

Asynchronous hooks run in the background without blocking.

```bash
gh_hook_pr_merged_async() {
  local pr_title="$1"
  local pr_number="$2"

  echo "Processing PR #${pr_number} in background..."
  # This runs in background, gh command returns immediately
  sleep 5
  echo "Done!"
}
```

**Use when:**
- Long-running operations (publishing packages, sending notifications)
- Non-critical tasks that can fail without affecting workflow
- Operations that don't need to complete before next command

### Using Both Versions Together

When both versions exist, **both are executed**:

1. The `_async` version starts first in the background (non-blocking)
2. The sync version runs immediately after (blocking)

```bash
# Async version runs in background
gh_hook_pr_merged_async() {
  echo "Async: Starting long operation..."
  sleep 10
  echo "Async: Done!"
}

# Sync version runs and blocks
gh_hook_pr_merged() {
  echo "Sync: Performing critical operation..."
  sleep 2
  echo "Sync: Done!"
}

# Execution order:
# 1. "Async: Starting long operation..." (starts in background)
# 2. "Sync: Performing critical operation..." (blocks)
# 3. "Sync: Done!" (after 2 seconds)
# 4. "Async: Done!" (after 10 seconds total, in background)
```

**Benefits of using both:**
- Start long-running tasks in the background (package publish, notifications)
- Perform critical operations synchronously (git operations, local builds)
- Maximize efficiency by running both in parallel

**Practical example:**
```bash
# Async: Publish to crates.io (takes 2-3 minutes)
gh_hook_release_pr_merged_async() {
  local version="$1"
  cargo publish
}

# Sync: Create GitHub release (must complete before returning)
gh_hook_release_pr_merged() {
  local version="$1"
  gh release create "v${version}"
}
```

### Examples

**Long-running publish operation (async recommended):**
```bash
gh_hook_release_pr_merged_async() {
  local version="$1"

  cargo publish  # May take minutes
  gh release create "v${version}"
}
```

**Critical pre-merge validation (must be sync):**
```bash
gh_hook_before_merge() {
  local pr_number="$1"

  # Must complete before merge
  if ! ./scripts/validate.sh; then
    echo "Validation failed!"
    return 1  # Abort merge
  fi
}
```

**Non-critical notification (async recommended):**
```bash
gh_hook_pr_created_async() {
  local pr_number="$1"
  local pr_url="$2"

  # Send notification without blocking
  curl -X POST "$SLACK_WEBHOOK" \
    -d "{\"text\":\"New PR: ${pr_url}\"}"
}
```

## Hook Function Signatures

### gh_hook_pr_merged

```bash
gh_hook_pr_merged() {
  local pr_title="$1"     # PR title
  local pr_number="$2"    # PR number (integer)

  # Your code here
}
```

**When:** After `gh pr merge` succeeds (for non-release PRs)

### gh_hook_release_pr_merged

```bash
gh_hook_release_pr_merged() {
  local version="$1"      # Extracted version (e.g., "1.2.3")

  # Your code here
}
```

**When:** After `gh pr merge` succeeds (for release PRs only)

### gh_hook_pr_created

```bash
gh_hook_pr_created() {
  local pr_number="$1"    # PR number
  local pr_url="$2"       # Full PR URL

  # Your code here
}
```

**When:** After `gh pr create` succeeds

### gh_hook_pr_closed

```bash
gh_hook_pr_closed() {
  local pr_number="$1"    # PR number

  # Your code here
}
```

**When:** After `gh pr close` succeeds

### gh_hook_release_created

```bash
gh_hook_release_created() {
  local tag_name="$1"     # Tag name (e.g., "v1.2.3")
  local release_url="$2"  # Full release URL

  # Your code here
}
```

**When:** After `gh release create` succeeds

## Common Patterns

### Pattern 1: Conditional Execution

```bash
gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  # Skip for certain branches
  local current_branch=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$current_branch" == "develop" ]]; then
    echo "Skipping hook for develop branch"
    return 0
  fi

  # Skip for draft PRs
  if [[ "$pr_title" == *"[Draft]"* ]]; then
    echo "Skipping hook for draft PR"
    return 0
  fi

  # Your main logic here
}
```

### Pattern 2: Environment Variable Checks

```bash
gh_hook_release_pr_merged() {
  local version="$1"

  # Check required environment variables
  if [ -z "$GITHUB_TOKEN" ]; then
    _gh_hooks_warn "GITHUB_TOKEN not set, skipping release-please"
    return 0
  fi

  if [ -z "$CARGO_REGISTRY_TOKEN" ]; then
    _gh_hooks_warn "CARGO_REGISTRY_TOKEN not set, skipping cargo publish"
    return 0
  fi

  # Proceed with publishing
  cargo publish
}
```

### Pattern 3: Error Handling

```bash
gh_hook_release_pr_merged() {
  local version="$1"

  # Try to publish, but don't fail the gh command if it fails
  if cargo publish; then
    _gh_hooks_info "Published to crates.io successfully"
  else
    local exit_code=$?
    _gh_hooks_error "cargo publish failed with exit code ${exit_code}"

    # Check for common errors
    if [ $exit_code -eq 101 ]; then
      _gh_hooks_info "Crate may already be published"
    fi

    # Return 0 to not fail the gh command
    return 0
  fi

  # Create GitHub release
  if gh release create "v${version}" --notes-file CHANGELOG.md; then
    _gh_hooks_info "GitHub release created"
  else
    _gh_hooks_error "Failed to create GitHub release"
    return 0  # Still return success
  fi
}
```

### Pattern 4: Parallel Execution

```bash
gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  # Run multiple tasks in parallel
  {
    send_slack_notification "PR #${pr_number} merged"
  } &

  {
    update_documentation
  } &

  {
    trigger_deployment
  } &

  # Wait for all background jobs
  wait
}
```

### Pattern 5: Sequential Steps

```bash
gh_hook_release_pr_merged() {
  local version="$1"

  # Step 1: Build
  _gh_hooks_info "Building..."
  if ! cargo build --release; then
    _gh_hooks_error "Build failed"
    return 0
  fi

  # Step 2: Test
  _gh_hooks_info "Testing..."
  if ! cargo test; then
    _gh_hooks_error "Tests failed"
    return 0
  fi

  # Step 3: Publish
  _gh_hooks_info "Publishing..."
  cargo publish
}
```

## Advanced Techniques

### Using Git Information

```bash
gh_hook_pr_merged() {
  # Get current branch
  local branch=$(git rev-parse --abbrev-ref HEAD)

  # Get commit hash
  local commit=$(git rev-parse HEAD)

  # Get commit message
  local commit_msg=$(git log -1 --pretty=%B)

  # Get repository URL
  local repo_url=$(git config --get remote.origin.url)

  echo "Branch: $branch"
  echo "Commit: $commit"
  echo "Message: $commit_msg"
  echo "Repo: $repo_url"
}
```

### Parsing PR Information

```bash
gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  # Extract issue number from PR title
  # e.g., "fix: resolve #123 - bug description"
  if [[ "$pr_title" =~ \#([0-9]+) ]]; then
    local issue_number="${BASH_REMATCH[1]}"
    echo "Related issue: #${issue_number}"

    # Close the issue
    command gh issue close "$issue_number"
  fi
}
```

### Multi-Project Configuration

```bash
#!/bin/bash

# Determine project type
PROJECT_TYPE="unknown"
if [ -f "Cargo.toml" ]; then
  PROJECT_TYPE="rust"
elif [ -f "package.json" ]; then
  PROJECT_TYPE="node"
elif [ -f "go.mod" ]; then
  PROJECT_TYPE="go"
fi

gh_hook_release_pr_merged() {
  local version="$1"

  case "$PROJECT_TYPE" in
    rust)
      cargo publish
      ;;
    node)
      npm publish
      ;;
    go)
      # Go modules don't need explicit publish
      _gh_hooks_info "Go module published via git tag"
      ;;
    *)
      _gh_hooks_warn "Unknown project type"
      ;;
  esac

  # Create GitHub release (common for all)
  gh release create "v${version}" --generate-notes
}
```

### Using External Scripts

```bash
gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  # Call external script
  if [ -f "./scripts/post-merge.sh" ]; then
    ./scripts/post-merge.sh "$pr_number" "$pr_title"
  fi
}
```

### Temporary File Management

```bash
gh_hook_release_pr_merged() {
  local version="$1"

  # Create temp directory
  local temp_dir=$(mktemp -d)

  # Do work in temp directory
  (
    cd "$temp_dir"
    # Your operations here
  )

  # Clean up
  rm -rf "$temp_dir"
}
```

## Testing Hooks

### Manual Testing

```bash
# Enable debug mode
export GH_HOOKS_DEBUG=1

# Test your hooks
gh pr merge 123 --squash

# Check for errors
echo $?
```

### Dry Run Function

Add to your `.gh-hooks.sh`:

```bash
# Test hook without executing commands
gh_hooks_test() {
  export DRY_RUN=1

  gh_hook_pr_merged "test: sample PR" "999"

  unset DRY_RUN
}

gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY RUN] Would run: npx release-please ..."
    return 0
  fi

  # Actual implementation
  npx release-please ...
}
```

### Syntax Checking

```bash
# Check syntax before using
bash -n .gh-hooks.sh
```

### Unit Testing with Bats

```bash
# install bats
brew install bats-core

# Create test file: test/.gh-hooks.bats
#!/usr/bin/env bats

setup() {
  source .gh-hooks.sh
}

@test "gh_hook_pr_merged exists" {
  type gh_hook_pr_merged
}

@test "gh_hook_pr_merged handles draft PRs" {
  run gh_hook_pr_merged "[Draft] test" "123"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Skipping"* ]]
}

# Run tests
bats test/.gh-hooks.bats
```

## Examples

### Example 1: Slack Notification

```bash
#!/bin/bash

SLACK_WEBHOOK="${SLACK_WEBHOOK_URL}"

gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  local repo=$(_gh_hooks_get_repo_slug)
  local message="PR merged in ${repo}: #${pr_number} - ${pr_title}"

  curl -X POST "$SLACK_WEBHOOK" \
    -H "Content-Type: application/json" \
    -d "{\"text\": \"${message}\"}"
}
```

### Example 2: Multi-Environment Deployment

```bash
#!/bin/bash

gh_hook_release_pr_merged() {
  local version="$1"

  # Publish package
  cargo publish

  # Deploy to staging
  _gh_hooks_info "Deploying to staging..."
  ./deploy.sh staging "v${version}"

  # Wait for user confirmation
  read -p "Deploy to production? (y/N) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    _gh_hooks_info "Deploying to production..."
    ./deploy.sh production "v${version}"
  fi
}
```

### Example 3: Automated Changelog Update

```bash
#!/bin/bash

gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  # Add entry to CHANGELOG.md
  local date=$(date +%Y-%m-%d)
  local entry="- ${pr_title} (#${pr_number})"

  # Insert after "## Unreleased" heading
  sed -i.bak "/^## Unreleased$/a\\
${entry}
" CHANGELOG.md

  # Commit the change
  git add CHANGELOG.md
  git commit -m "docs: update CHANGELOG for PR #${pr_number}"
  git push
}
```

### Example 4: Conditional Release Strategy

```bash
#!/bin/bash

gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  # Determine release type from PR title
  local release_type=""

  if [[ "$pr_title" == feat:* ]]; then
    release_type="minor"
  elif [[ "$pr_title" == fix:* ]]; then
    release_type="patch"
  elif [[ "$pr_title" == *BREAKING* ]]; then
    release_type="major"
  else
    _gh_hooks_info "No release needed for this PR"
    return 0
  fi

  _gh_hooks_info "Creating ${release_type} release..."

  npx release-please release-pr \
    --token="${GITHUB_TOKEN}" \
    --repo-url="$(_gh_hooks_get_repo_slug)" \
    --release-type=rust \
    --bump="${release_type}"
}
```

## Best Practices

1. **Always return 0**: Don't fail the gh command due to hook errors
2. **Check prerequisites**: Validate environment variables and dependencies
3. **Use logging functions**: `_gh_hooks_debug`, `_gh_hooks_info`, `_gh_hooks_warn`, `_gh_hooks_error`
4. **Handle errors gracefully**: Use `if` statements, don't rely on `set -e`
5. **Document your hooks**: Add comments explaining what each hook does
6. **Test thoroughly**: Use debug mode and test in a safe environment
7. **Keep it simple**: Don't overcomplicate; hooks should be readable
8. **Avoid infinite loops**: Don't call `gh` without `command` prefix

## Troubleshooting

### Hook Not Called

- Verify hook function name is correct
- Check if `.gh-hooks.sh` exists in project root
- Enable debug mode: `export GH_HOOKS_DEBUG=1`
- Test syntax: `bash -n .gh-hooks.sh`

### Hook Fails

- Check return values (should return 0)
- Verify environment variables are set
- Look for typos in commands
- Test commands individually outside hooks

### Permission Issues

- Ensure `.gh-hooks.sh` is executable: `chmod +x .gh-hooks.sh`
- Check file ownership
- Verify git repository permissions

## Further Reading

- [API.md](API.md) - Complete API reference
- [README.md](../README.md) - Usage guide
- [examples/](../examples/) - Example templates
