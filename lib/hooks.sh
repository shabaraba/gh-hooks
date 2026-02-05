#!/bin/bash
# lib/hooks.sh - Hook execution engine for gh-hooks

_GH_HOOKS_IN_EXECUTION=0

_gh_hooks_call() {
  local hook_name="$1"
  shift

  if [ "$_GH_HOOKS_IN_EXECUTION" = "1" ]; then
    _gh_hooks_error "Infinite loop detected: hook calling gh command"
    return 1
  fi

  if ! type "$hook_name" >/dev/null 2>&1; then
    _gh_hooks_debug "Hook '$hook_name' not defined, skipping"
    return 0
  fi

  _gh_hooks_debug "Calling hook: $hook_name $*"

  _GH_HOOKS_IN_EXECUTION=1
  trap '_GH_HOOKS_IN_EXECUTION=0' EXIT INT TERM

  local exit_code=0
  "$hook_name" "$@" || exit_code=$?

  _GH_HOOKS_IN_EXECUTION=0
  trap - EXIT INT TERM

  if [ $exit_code -ne 0 ]; then
    _gh_hooks_error "Hook '$hook_name' failed with exit code $exit_code"
  else
    _gh_hooks_debug "Hook '$hook_name' completed successfully"
  fi
}

_gh_hooks_is_release_pr() {
  local pr_title="$1"
  local pattern="${GH_HOOKS_RELEASE_PATTERN:-^chore\(main\): release}"

  _gh_hooks_debug "Checking if release PR: '$pr_title' matches '$pattern'"

  [[ "$pr_title" =~ $pattern ]]
}

_gh_hooks_extract_version() {
  local version="" file="" cmd=""
  local -a sources=(
    "CHANGELOG.md:grep -m1 '^## \\[' CHANGELOG.md"
    "Cargo.toml:grep -m1 '^version = ' Cargo.toml"
    "package.json:grep -m1 '\"version\"' package.json"
  )

  for source in "${sources[@]}"; do
    file="${source%%:*}"
    cmd="${source#*:}"

    [ -f "$file" ] || continue

    version=$(eval "$cmd" 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?(\+[a-zA-Z0-9.]+)?' | head -1 | sed 's/^v//')
    if [ -n "$version" ]; then
      _gh_hooks_debug "Version extracted from $file: $version"
      echo "$version"
      return 0
    fi
  done

  _gh_hooks_warn "Could not extract version from CHANGELOG.md, Cargo.toml, or package.json"
  return 1
}

_gh_hooks_handle_pr_merge() {
  _gh_hooks_info "PR merge hook triggered"

  local pr_number pr_title
  pr_number=$(command gh pr view --json number -q .number 2>/dev/null)
  pr_title=$(command gh pr view --json title -q .title 2>/dev/null)

  if [ -z "$pr_number" ] || [ -z "$pr_title" ]; then
    _gh_hooks_error "Could not get PR number or title"
    return 1
  fi

  _gh_hooks_debug "PR #$pr_number: $pr_title"

  if _gh_hooks_is_release_pr "$pr_title"; then
    _gh_hooks_info "Detected release PR"

    local version
    version=$(_gh_hooks_extract_version)

    if [ -n "$version" ]; then
      _gh_hooks_call gh_hook_release_pr_merged "$version"
    else
      _gh_hooks_warn "Release PR detected but could not extract version"
      _gh_hooks_call gh_hook_pr_merged "$pr_title" "$pr_number"
    fi
  else
    _gh_hooks_call gh_hook_pr_merged "$pr_title" "$pr_number"
  fi
}

_gh_hooks_handle_pr_create() {
  _gh_hooks_info "PR create hook triggered"

  local pr_number pr_url
  pr_number=$(command gh pr view --json number -q .number 2>/dev/null)
  pr_url=$(command gh pr view --json url -q .url 2>/dev/null)

  if [ -z "$pr_number" ] || [ -z "$pr_url" ]; then
    _gh_hooks_error "Could not get PR number or URL"
    return 1
  fi

  _gh_hooks_debug "Created PR #$pr_number: $pr_url"
  _gh_hooks_call gh_hook_pr_created "$pr_number" "$pr_url"
}

_gh_hooks_handle_pr_close() {
  _gh_hooks_info "PR close hook triggered"

  local pr_number
  pr_number=$(command gh pr view --json number -q .number 2>/dev/null)

  if [ -z "$pr_number" ]; then
    _gh_hooks_error "Could not get PR number"
    return 1
  fi

  _gh_hooks_debug "Closed PR #$pr_number"
  _gh_hooks_call gh_hook_pr_closed "$pr_number"
}

_gh_hooks_handle_release_create() {
  _gh_hooks_info "Release create hook triggered"

  local tag_name release_url
  tag_name=$(command gh release view --json tagName -q .tagName 2>/dev/null)
  release_url=$(command gh release view --json url -q .url 2>/dev/null)

  if [ -z "$tag_name" ]; then
    _gh_hooks_error "Could not get release tag name"
    return 1
  fi

  _gh_hooks_debug "Created release: $tag_name"
  _gh_hooks_call gh_hook_release_created "$tag_name" "$release_url"
}
