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

export GH_HOOKS_RELEASE_PATTERN="${GH_HOOKS_RELEASE_PATTERN:-^chore\(main\): release}"
export GH_HOOKS_DEBUG="${GH_HOOKS_DEBUG:-0}"

gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  echo "ok: PR #${pr_number} merged: ${pr_title}"
  _gh_hooks_run_release_please rust
}

gh_hook_release_pr_merged() {
  local version="$1"

  echo "ok: Release PR merged for version ${version}"
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

# gh_hook_pr_created() {
#   local pr_number="$1"
#   local pr_url="$2"
#   echo "ok: PR #${pr_number} created: ${pr_url}"
# }

# gh_hook_pr_closed() {
#   local pr_number="$1"
#   echo "ok: PR #${pr_number} closed"
# }
