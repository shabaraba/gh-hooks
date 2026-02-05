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

  # release-pleaseを実行
  _gh_hooks_run_release_please simple
}

# リリースPRマージ時: GitHubリリースを作成
gh_hook_release_pr_merged() {
  local version="$1"

  echo "✓ Release PR merged for version ${version}"

  # GitHubリリースを作成
  _gh_hooks_create_github_release "$version"
}
