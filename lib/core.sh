#!/bin/bash
# lib/core.sh - Core orchestration for gh-hooks

_GH_HOOKS_PROJECT_ROOT=""
_GH_HOOKS_CONFIG_LOADED=0

_gh_hooks_find_project_root() {
  if [ -n "$_GH_HOOKS_PROJECT_ROOT" ]; then
    echo "$_GH_HOOKS_PROJECT_ROOT"
    return 0
  fi

  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.git" ]; then
      _GH_HOOKS_PROJECT_ROOT="$dir"
      _gh_hooks_debug "Project root found: $dir"
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done

  _gh_hooks_debug "Project root not found (no .git directory)"
  return 1
}

_gh_hooks_load_config() {
  if [ "$_GH_HOOKS_CONFIG_LOADED" = "1" ]; then
    _gh_hooks_debug "Config already loaded"
    return 0
  fi

  local project_root
  project_root=$(_gh_hooks_find_project_root) || {
    _gh_hooks_debug "Cannot load config: not in a git repository"
    return 1
  }

  local config_file="${project_root}/.gh-hooks.sh"

  if [ ! -f "$config_file" ]; then
    _gh_hooks_debug "No .gh-hooks.sh found in project root"
    return 1
  fi

  if [ -w "$config_file" ] && [ ! -O "$config_file" ]; then
    _gh_hooks_warn "Config file is writable by others: $config_file"
    _gh_hooks_warn "Fix with: chmod 644 $config_file"
    return 1
  fi

  _gh_hooks_debug "Loading config from: $config_file"

  # shellcheck source=/dev/null
  if source "$config_file" 2>/dev/null; then
    _GH_HOOKS_CONFIG_LOADED=1
    _gh_hooks_debug "Config loaded successfully"
    return 0
  else
    _gh_hooks_error "Failed to load .gh-hooks.sh: syntax error"
    return 1
  fi
}

_gh_hooks_reset_config() {
  _GH_HOOKS_PROJECT_ROOT=""
  _GH_HOOKS_CONFIG_LOADED=0
}

_gh_hooks_dispatch() {
  local subcommand="$1"
  local action="$2"

  _gh_hooks_debug "Dispatching: gh $*"

  _gh_hooks_load_config || {
    _gh_hooks_debug "No config to load, skipping hooks"
    return 0
  }

  case "$subcommand" in
    pr)
      case "$action" in
        merge)  _gh_hooks_handle_pr_merge "$@" ;;
        create) _gh_hooks_handle_pr_create "$@" ;;
        close)  _gh_hooks_handle_pr_close "$@" ;;
        *)      _gh_hooks_debug "No hook for: gh pr $action" ;;
      esac
      ;;
    release)
      case "$action" in
        create) _gh_hooks_handle_release_create "$@" ;;
        *)      _gh_hooks_debug "No hook for: gh release $action" ;;
      esac
      ;;
    *)
      _gh_hooks_debug "No hook for: gh $subcommand"
      ;;
  esac
}

_gh_hooks_core_init() {
  if ! _gh_hooks_command_exists gh; then
    _gh_hooks_error "GitHub CLI (gh) is not installed"
    return 1
  fi

  if ! _gh_hooks_command_exists git; then
    _gh_hooks_error "Git is not installed"
    return 1
  fi

  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    _gh_hooks_debug "Not in a git repository"
    return 1
  fi

  return 0
}
