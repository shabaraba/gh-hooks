#!/bin/bash
# test_async_hooks.sh - Test script for async hook functionality

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the libraries
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/hooks.sh"

echo "Testing async hook functionality..."
echo ""

# Test 1: Synchronous hook
echo "Test 1: Synchronous hook execution"
gh_hook_test_sync() {
  echo "  [sync] Started at $(date +%T)"
  sleep 1
  echo "  [sync] Completed at $(date +%T)"
}
export -f gh_hook_test_sync

echo "  Calling sync hook..."
start_time=$(date +%s)
_gh_hooks_call gh_hook_test_sync
end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "  Elapsed time: ${elapsed}s (should be ~1s)"
echo ""

# Test 2: Asynchronous hook
echo "Test 2: Asynchronous hook execution"
gh_hook_test_async() {
  echo "  [async] Started at $(date +%T)"
  sleep 2
  echo "  [async] Completed at $(date +%T)"
}
export -f gh_hook_test_async

echo "  Calling async hook..."
start_time=$(date +%s)
_gh_hooks_call gh_hook_test_async
end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "  Elapsed time: ${elapsed}s (should be ~0s, hook runs in background)"
echo ""

# Test 3: Both versions defined (both should execute)
echo "Test 3: Both sync and async versions defined (both should execute)"
gh_hook_test_both() {
  echo "  [sync] Started at $(date +%T)"
  sleep 1
  echo "  [sync] Completed at $(date +%T)"
}
gh_hook_test_both_async() {
  echo "  [async] Started at $(date +%T)"
  sleep 3
  echo "  [async] Completed at $(date +%T)"
}
export -f gh_hook_test_both
export -f gh_hook_test_both_async

echo "  Calling with both versions defined..."
echo "  Expected: async starts in background, sync runs and blocks"
start_time=$(date +%s)
_gh_hooks_call_with_fallback gh_hook_test_both
end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "  Elapsed time: ${elapsed}s (should be ~1s for sync part)"
echo ""

# Test 4: Fallback to sync when only sync exists
echo "Test 4: Fallback to sync when only sync exists"
gh_hook_test_sync_only() {
  echo "  [sync only] This should be called"
}
export -f gh_hook_test_sync_only

echo "  Calling with fallback (only sync version defined)..."
_gh_hooks_call_with_fallback gh_hook_test_sync_only
echo ""

echo "All tests completed!"
echo ""
echo "Note: Wait a few seconds to see async hook outputs..."
