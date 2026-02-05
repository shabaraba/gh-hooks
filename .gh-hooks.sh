#!/bin/bash
# .gh-hooks.sh - gh-hooks project hooks configuration
#
# このプロジェクトはGitHub CLI拡張なので、release-pleaseによる
# 自動リリース管理のみを行います。

export GH_HOOKS_RELEASE_PATTERN="${GH_HOOKS_RELEASE_PATTERN:-^chore\(main\): release}"
export GH_HOOKS_DEBUG="${GH_HOOKS_DEBUG:-0}"

# 通常のPRマージ時: release-pleaseを実行してリリースPRを作成・更新
gh_hook_pr_merged() {
  local pr_title="$1"
  local pr_number="$2"

  echo "✓ PR #${pr_number} merged: ${pr_title}"

  # release-pleaseをローカルで実行してリリースPRを作成・更新
  if command -v npx >/dev/null 2>&1; then
    echo "Running release-please..."

    # release-pleaseを実行してリリースPRを作成
    npx release-please release-pr \
      --repo-url="shabaraba/gh-hooks" \
      --token="${GITHUB_TOKEN}" \
      --config-file=release-please-config.json \
      --manifest-file=.release-please-manifest.json

    if [ $? -eq 0 ]; then
      echo "✓ Release PR created/updated successfully"
    else
      echo "✗ Failed to run release-please (check GITHUB_TOKEN)"
    fi
  else
    echo "✗ npx not found - install Node.js to use release-please"
  fi
}

# リリースPRマージ時: GitHubリリースを作成
gh_hook_release_pr_merged() {
  local version="$1"

  echo "✓ Release PR merged for version ${version}"

  # GitHubリリースを作成
  if command -v npx >/dev/null 2>&1; then
    echo "Creating GitHub release for v${version}..."

    # release-pleaseでGitHubリリースを作成
    npx release-please github-release \
      --repo-url="shabaraba/gh-hooks" \
      --token="${GITHUB_TOKEN}" \
      --config-file=release-please-config.json \
      --manifest-file=.release-please-manifest.json

    if [ $? -eq 0 ]; then
      echo "✓ GitHub release v${version} created successfully"
    else
      echo "✗ Failed to create GitHub release (check GITHUB_TOKEN)"
    fi
  else
    echo "✗ npx not found - install Node.js to use release-please"
  fi
}
