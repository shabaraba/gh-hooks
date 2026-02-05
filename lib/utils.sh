#!/bin/bash
# lib/utils.sh - Logging and utility functions for gh-hooks

_GH_HOOKS_COLOR_RESET="\033[0m"
_GH_HOOKS_COLOR_RED="\033[31m"
_GH_HOOKS_COLOR_YELLOW="\033[33m"
_GH_HOOKS_COLOR_BLUE="\033[34m"
_GH_HOOKS_COLOR_GRAY="\033[90m"

_gh_hooks_has_color() {
  [ -t 1 ] && [ -n "${TERM}" ] && [ "${TERM}" != "dumb" ]
}

_gh_hooks_log() {
  local color="$1" label="$2" stream="$3"
  shift 3

  if _gh_hooks_has_color; then
    echo -e "${color}[gh-hooks${label:+ ${label}}]${_GH_HOOKS_COLOR_RESET} $*" >&"$stream"
  else
    echo "[gh-hooks${label:+ ${label}}] $*" >&"$stream"
  fi
}

_gh_hooks_debug() {
  [ "${GH_HOOKS_DEBUG:-0}" = "1" ] || return 0
  _gh_hooks_log "$_GH_HOOKS_COLOR_GRAY" "debug" 2 "$@"
}

_gh_hooks_info() {
  _gh_hooks_log "$_GH_HOOKS_COLOR_BLUE" "" 1 "$@"
}

_gh_hooks_warn() {
  _gh_hooks_log "$_GH_HOOKS_COLOR_YELLOW" "warning" 2 "$@"
}

_gh_hooks_error() {
  _gh_hooks_log "$_GH_HOOKS_COLOR_RED" "error" 2 "$@"
}

_gh_hooks_command_exists() {
  command -v "$1" >/dev/null 2>&1
}

_gh_hooks_get_repo_slug() {
  local url
  url=$(git config --get remote.origin.url 2>/dev/null) || return 1
  [ -z "$url" ] && return 1
  echo "$url" | sed -e 's/.*github\.com[:/]\(.*\)\.git/\1/' -e 's/.*github\.com[:/]\(.*\)/\1/'
}

_gh_hooks_run_release_please() {
  local release_type="$1"

  if [ -z "$GITHUB_TOKEN" ]; then
    echo "warning: GITHUB_TOKEN not set, skipping release-please"
    return 0
  fi

  local repo_slug
  repo_slug=$(_gh_hooks_get_repo_slug) || {
    echo "warning: Could not determine repository, skipping release-please"
    return 0
  }

  echo "-> Running release-please for ${repo_slug}..."

  if npx release-please release-pr \
    --token="${GITHUB_TOKEN}" \
    --repo-url="${repo_slug}" \
    --release-type="${release_type}"; then
    echo "ok: release-please completed successfully"
  else
    echo "warning: release-please failed (exit code: $?)"
  fi

  return 0
}

_gh_hooks_create_github_release() {
  local version="$1"
  local notes_args

  echo "-> Creating GitHub release v${version}..."

  if [ -f "CHANGELOG.md" ]; then
    notes_args=(--notes-file CHANGELOG.md)
  else
    notes_args=(--generate-notes)
  fi

  if command gh release create "v${version}" \
    --title "v${version}" \
    "${notes_args[@]}"; then
    echo "ok: GitHub release created successfully"
    return 0
  else
    echo "warning: Failed to create GitHub release"
    return 1
  fi
}
