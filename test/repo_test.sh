#!/usr/bin/env bash
# Checks that the scan cache hackmyagent writes into this tree
# (.hackmyagent-cache/) is ignored and that no file under it is tracked.
# Run from anywhere: bash test/repo_test.sh
set -euo pipefail

cd "$(dirname "$0")/.."
fail=0

tracked=$(git ls-files -- .hackmyagent-cache)
if [ -n "$tracked" ]; then
  echo "FAIL: files under .hackmyagent-cache/ are tracked:"
  echo "$tracked"
  fail=1
fi

if ! git check-ignore -q --no-index .hackmyagent-cache/budget.json; then
  echo "FAIL: .hackmyagent-cache/ is not ignored"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: .hackmyagent-cache/ is ignored and untracked"
fi
exit "$fail"
