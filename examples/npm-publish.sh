#!/bin/bash
# examples/npm-publish.sh - Template for npm projects with npm publish
#
# USAGE:
#   1. Copy this file to your project root as .gh-hooks.sh
#   2. Customize the functions below for your needs
#   3. Set required environment variables (GITHUB_TOKEN, NPM_TOKEN)
#
# REQUIREMENTS:
#   - GitHub CLI (gh)
#   - release-please (npx release-please)
#   - npm
#   - GITHUB_TOKEN environment variable
#   - NPM_TOKEN environment variable (for npm publish)
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
  _gh_hooks_run_release_please node
}

# Asynchronous version (runs in background, recommended for long operations)
# gh_hook_pr_merged_async() {
#   local pr_title="$1"
#   local pr_number="$2"
#
#   echo "ok: PR #${pr_number} merged: ${pr_title}"
#   _gh_hooks_run_release_please node
# }

# Synchronous version (blocks until completion)
gh_hook_release_pr_merged() {
  local version="$1"

  echo "ok: Release PR merged for version ${version}"

  # Pull latest changes to ensure package.json has the updated version
  echo "-> Pulling latest changes..."
  if git pull origin main; then
    echo "ok: Successfully pulled latest changes"
  else
    echo "warning: Failed to pull latest changes"
  fi

  echo "-> Publishing to npm..."

  if [ -z "$NPM_TOKEN" ]; then
    echo "warning: NPM_TOKEN not set, skipping npm publish"
    echo "  Set NPM_TOKEN in your environment or .npmrc"
  else
    if npm publish; then
      echo "ok: Published to npm successfully"
    else
      echo "warning: npm publish failed (exit code: $?)"
    fi
  fi

  _gh_hooks_create_github_release "$version"
}

# Asynchronous version (runs in background, recommended for publishing)
# gh_hook_release_pr_merged_async() {
#   local version="$1"
#
#   echo "ok: Release PR merged for version ${version}"
#   echo "-> Publishing to npm (async)..."
#
#   if [ -z "$NPM_TOKEN" ]; then
#     echo "warning: NPM_TOKEN not set, skipping npm publish"
#     echo "  Set NPM_TOKEN in your environment or .npmrc"
#   else
#     if npm publish; then
#       echo "ok: Published to npm successfully"
#     else
#       echo "warning: npm publish failed (exit code: $?)"
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
#   # Long-running: Publish to npm (1-2 minutes)
#   npm publish
# }
#
# gh_hook_release_pr_merged() {
#   local version="$1"
#   # Critical: Create GitHub release (must complete before returning)
#   _gh_hooks_create_github_release "$version"
#   # Optional: Send notification
#   curl -X POST "$SLACK_WEBHOOK" -d "{\"text\":\"Released v${version}\"}"
# }
