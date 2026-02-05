#!/usr/bin/env bash
# gh-hooks.sh - GitHub CLI hooks system

_GH_HOOKS_VERSION="0.1.0"

# Detect script directory (compatible with bash and zsh)
if [ -n "${BASH_SOURCE[0]}" ]; then
  _GH_HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [ -n "${ZSH_VERSION}" ]; then
  _GH_HOOKS_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
  _GH_HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# shellcheck source=lib/utils.sh
source "${_GH_HOOKS_DIR}/lib/utils.sh"
# shellcheck source=lib/core.sh
source "${_GH_HOOKS_DIR}/lib/core.sh"
# shellcheck source=lib/hooks.sh
source "${_GH_HOOKS_DIR}/lib/hooks.sh"

gh() {
  # Lazy initialization: check requirements on first use
  if [ -z "${_GH_HOOKS_INITIALIZED:-}" ]; then
    if ! _gh_hooks_command_exists gh; then
      _gh_hooks_error "GitHub CLI (gh) is not installed"
      return 1
    fi
    if ! _gh_hooks_command_exists git; then
      _gh_hooks_error "Git is not installed"
      return 1
    fi
    export _GH_HOOKS_INITIALIZED=1
  fi

  command gh "$@"
  local exit_code=$?

  if [ $exit_code -eq 0 ] && \
     [ "${GH_HOOKS_ENABLED:-1}" = "1" ] && \
     [ "${_GH_HOOKS_IN_EXECUTION:-0}" = "0" ]; then
    _gh_hooks_dispatch "$@"
  fi

  return $exit_code
}

gh_disable_hooks() {
  export GH_HOOKS_ENABLED=0
  _gh_hooks_info "Hooks disabled (set GH_HOOKS_ENABLED=1 to re-enable)"
}

gh_enable_hooks() {
  export GH_HOOKS_ENABLED=1
  _gh_hooks_info "Hooks enabled"
}

gh_hooks_status() {
  local hooks=(
    gh_hook_pr_merged
    gh_hook_pr_created
    gh_hook_pr_closed
    gh_hook_release_pr_merged
    gh_hook_release_created
    gh_hook_before_merge
  )

  echo "gh-hooks status:"
  echo "  Version: ${_GH_HOOKS_VERSION}"
  echo "  Enabled: ${GH_HOOKS_ENABLED:-1}"
  echo "  Debug: ${GH_HOOKS_DEBUG:-0}"
  echo "  Install directory: ${_GH_HOOKS_DIR}"

  local project_root
  if project_root=$(_gh_hooks_find_project_root 2>/dev/null); then
    echo "  Project root: ${project_root}"

    if [ -f "${project_root}/.gh-hooks.sh" ]; then
      echo "  Config file: ${project_root}/.gh-hooks.sh (found)"
      echo "  Defined hooks:"
      for hook in "${hooks[@]}"; do
        if type "$hook" >/dev/null 2>&1; then
          echo "    - $hook"
        fi
      done
    else
      echo "  Config file: ${project_root}/.gh-hooks.sh (not found)"
    fi
  else
    echo "  Project root: not in a git repository"
  fi
}

gh_hooks_help() {
  cat <<EOF
gh-hooks - GitHub CLI hooks system (v${_GH_HOOKS_VERSION})

USAGE:
  Source this file in your shell configuration:
    source ~/.gh-hooks/gh-hooks.sh

  Then use gh commands normally. Hooks will be triggered automatically.

COMMANDS:
  gh_hooks_status        Show current hooks status
  gh_disable_hooks       Temporarily disable hooks
  gh_enable_hooks        Re-enable hooks
  gh_hooks_help          Show this help message

HOOK FUNCTIONS:
  Define these functions in your project's .gh-hooks.sh file:

  gh_hook_pr_merged <title> <number>
    Called after a PR is merged

  gh_hook_release_pr_merged <version>
    Called after a release PR is merged

  gh_hook_pr_created <number> <url>
    Called after a PR is created

  gh_hook_pr_closed <number>
    Called after a PR is closed

  gh_hook_release_created <tag> <url>
    Called after a release is created

  gh_hook_before_merge <number>
    Called before merging a PR (return 1 to abort)

ENVIRONMENT VARIABLES:
  GH_HOOKS_ENABLED=1           Enable/disable hooks (0=disabled, 1=enabled)
  GH_HOOKS_DEBUG=0             Debug mode (0=off, 1=on)
  GH_HOOKS_RELEASE_PATTERN     Pattern to detect release PRs
                               (default: "^chore\(main\): release")

EXAMPLES:
  See examples/ directory for templates:
    - rust-crates.sh    Rust projects with cargo publish
    - npm-publish.sh    npm projects with npm publish

DOCUMENTATION:
  README.md       Quick start guide
  INSTALL.md      Installation instructions
  docs/API.md     Detailed API documentation

EOF
}

# Export functions for bash (zsh doesn't need this)
if [ -n "$BASH_VERSION" ]; then
  _gh_hooks_debug "Running in bash mode"
  export -f gh
  export -f gh_disable_hooks
  export -f gh_enable_hooks
  export -f gh_hooks_status
  export -f gh_hooks_help
elif [ -n "$ZSH_VERSION" ]; then
  _gh_hooks_debug "Running in zsh mode"
fi

_gh_hooks_debug "gh-hooks loaded successfully"
