#!/bin/bash
# examples/rust-crates.sh - Template for Rust projects with cargo publish
#
# USAGE:
#   1. Copy this file to your project root as .gh-hooks.sh
#   2. Customize the functions below for your needs
#   3. Set required environment variables (GITHUB_TOKEN)
#
# REQUIREMENTS:
#   - GitHub CLI (gh)
#   - release-please (npx release-please)
#   - cargo (Rust toolchain)
#   - GITHUB_TOKEN environment variable
#
# HOOK TYPES:
#   - Synchronous hooks: Block until completion (default)
#   - Asynchronous hooks: Add '_async' suffix to run in background
#   - If both versions exist, both are executed:
#     1. Async version starts in background (non-blocking)
#     2. Sync version runs immediately after (blocking)

export GH_HOOKS_RELEASE_PATTERN="${GH_HOOKS_RELEASE_PATTERN:-^chore\(main\): release}"
export GH_HOOKS_DEBUG="${GH_HOOKS_DEBUG:-0}"

# Synchronous version (blocks until completion)
gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  echo "ok: PR #${pr_number} merged: ${pr_title}"
  _gh_hooks_run_release_please rust
}

# Asynchronous version (runs in background, recommended for long operations)
# gh_hook_pr_merged_async() {
#   local pr_title="$1"
#   local pr_number="$2"
#
#   echo "ok: PR #${pr_number} merged: ${pr_title}"
#   _gh_hooks_run_release_please rust
# }

# Synchronous version (blocks until completion)
gh_hook_release_pr_merged() {
  local version="$1"

  echo "ok: Release PR merged for version ${version}"

  # Pull latest changes to ensure Cargo.toml has the updated version
  echo "-> Pulling latest changes..."
  if git pull origin main; then
    echo "ok: Successfully pulled latest changes"
  else
    echo "warning: Failed to pull latest changes"
  fi

  echo "-> Publishing to crates.io..."

  if cargo publish; then
    echo "ok: Published to crates.io successfully"
  else
    local exit_code=$?
    echo "warning: cargo publish failed (exit code: ${exit_code})"
    if [ $exit_code -eq 101 ]; then
      echo "  (This might be because the crate is already published)"
    fi
  fi

  _gh_hooks_create_github_release "$version"
}

# Asynchronous version (runs in background, recommended for publishing)
# gh_hook_release_pr_merged_async() {
#   local version="$1"
#
#   echo "ok: Release PR merged for version ${version}"
#   echo "-> Publishing to crates.io (async)..."
#
#   if cargo publish; then
#     echo "ok: Published to crates.io successfully"
#   else
#     local exit_code=$?
#     echo "warning: cargo publish failed (exit code: ${exit_code})"
#     if [ $exit_code -eq 101 ]; then
#       echo "  (This might be because the crate is already published)"
#     fi
#   fi
#
#   _gh_hooks_create_github_release "$version"
# }

# Example: Using both async and sync together
# This pattern is useful when you want to:
#   - Start long-running publish in background (async)
#   - Perform critical operations that must complete (sync)
#
# gh_hook_release_pr_merged_async() {
#   local version="$1"
#   # Long-running: Publish to crates.io (2-3 minutes)
#   cargo publish
# }
#
# gh_hook_release_pr_merged() {
#   local version="$1"
#   # Critical: Create GitHub release (must complete before returning)
#   _gh_hooks_create_github_release "$version"
#   # Optional: Send notification
#   curl -X POST "$SLACK_WEBHOOK" -d "{\"text\":\"Released v${version}\"}"
# }

# Optional: Synchronous hook for PR creation
# gh_hook_pr_created() {
#   local pr_number="$1"
#   local pr_url="$2"
#   echo "ok: PR #${pr_number} created: ${pr_url}"
# }

# Optional: Asynchronous hook for PR creation (e.g., send notification)
# gh_hook_pr_created_async() {
#   local pr_number="$1"
#   local pr_url="$2"
#   echo "ok: PR #${pr_number} created: ${pr_url}"
#   # curl -X POST https://hooks.slack.com/... -d "{\"text\":\"PR created: ${pr_url}\"}"
# }

# Optional: Synchronous hook for PR close
# gh_hook_pr_closed() {
#   local pr_number="$1"
#   echo "ok: PR #${pr_number} closed"
# }

# Optional: Asynchronous hook for PR close
# gh_hook_pr_closed_async() {
#   local pr_number="$1"
#   echo "ok: PR #${pr_number} closed"
# }
