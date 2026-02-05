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

  # release-pleaseをGitHub Actionsで実行
  # Note: ローカルからWorkflow Dispatchを使ってrelease-pleaseを起動
  if command -v gh >/dev/null 2>&1; then
    echo "Running release-please via GitHub Actions..."
    command gh workflow run release-please.yml 2>/dev/null || {
      echo "Note: release-please workflow not configured yet"
      echo "Create .github/workflows/release-please.yml to enable automatic releases"
    }
  fi
}

# リリースPRマージ時: GitHubリリースを作成
gh_hook_release_pr_merged() {
  local version="$1"

  echo "✓ Release PR merged for version ${version}"

  # GitHubリリースはrelease-pleaseのワークフローが自動的に作成するため
  # ここでは特に何もしない
  echo "GitHub release will be created automatically by release-please workflow"
}
