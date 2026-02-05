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

export GH_HOOKS_RELEASE_PATTERN="${GH_HOOKS_RELEASE_PATTERN:-^chore\(main\): release}"
export GH_HOOKS_DEBUG="${GH_HOOKS_DEBUG:-0}"

gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  echo "ok: PR #${pr_number} merged: ${pr_title}"
  _gh_hooks_run_release_please node
}

gh_hook_release_pr_merged() {
  local version="$1"

  echo "ok: Release PR merged for version ${version}"
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
