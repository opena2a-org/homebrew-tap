#!/usr/bin/env bash
# Checks that the scan cache hackmyagent writes into this tree
# (.hackmyagent-cache/) is ignored and that no file under it is tracked,
# and that the tracked .gitignore covers the credential and key file
# patterns hackmyagent secure expects (.env, secrets.json, *.pem, *.key).
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

# A global excludes file or .git/info/exclude does not travel with a clone,
# so each path must be matched by a pattern in the tracked .gitignore.
for path in .env secrets.json server.pem server.key Formula/server.key; do
  src=$(git check-ignore -v --no-index "$path" | cut -d: -f1 || true)
  if [ "$src" != ".gitignore" ]; then
    echo "FAIL: $path is not ignored by .gitignore"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: .hackmyagent-cache/ is ignored and untracked; .gitignore covers credential and key files"
fi
exit "$fail"
