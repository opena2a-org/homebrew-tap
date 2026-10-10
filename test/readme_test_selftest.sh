#!/usr/bin/env bash
# Runs test/readme_test.sh against README.md, which must pass, and against
# edited copies of it that each break one rule, which must fail with that
# rule's message.
# Run from anywhere: bash test/readme_test_selftest.sh
set -euo pipefail

cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail=0
cases=0

if ! out=$(bash test/readme_test.sh README.md); then
  echo "FAIL: README.md itself does not pass:"
  echo "$out"
  fail=1
fi

# expect_fail <name> <expected FAIL message> <sed script>
expect_fail() {
  local name=$1 message=$2 script=$3 copy="$tmp/$1.md" out
  cases=$((cases + 1))
  sed -e "$script" README.md > "$copy"
  if cmp -s README.md "$copy"; then
    echo "FAIL: $name: the edit did not change README.md"
    fail=1
  elif out=$(bash test/readme_test.sh "$copy"); then
    echo "FAIL: $name: readme_test.sh passed an edited README"
    fail=1
  elif ! grep -qF "$message" <<<"$out"; then
    echo "FAIL: $name: expected \"$message\", got:"
    echo "$out"
    fail=1
  fi
}

install="FAIL: brew install of a formula"
expect_fail prompt-line "$install" 's|^\$ brew install opena2a-org/tap/opena2a$|$ brew install opena2a|'
expect_fail indented "$install" 's|^brew install opena2a-org/tap/hackmyagent .*|    brew install hackmyagent|'
expect_fail second-argument "$install" 's|^brew install opena2a-org/tap/opena2a$|brew install opena2a-org/tap/opena2a hackmyagent|'
expect_fail tap-name-in-comment "$install" 's|^brew install opena2a-org/tap/secretless-ai .*|brew install secretless-ai   # or brew install opena2a-org/tap/secretless-ai|'
expect_fail unknown-formula "$install" 's|^brew install opena2a-org/tap/ai-trust .*|brew install opena2a-org/tap/opena2a-cli|'
expect_fail upgrade-several "FAIL: brew upgrade names several formulae" 's|^brew upgrade opena2a .*|brew upgrade opena2a secretless-ai hackmyagent ai-trust|'
expect_fail standalone-not-installed "FAIL: section runs a standalone tool" '$a\
\
## Scan\
\
```bash\
hackmyagent secure\
```'
expect_fail auto-install "FAIL: README says opena2a installs" 's|^npm install -g opena2a-cli .*|npm install -g opena2a-cli      # Full suite (auto-installs HMA, Secretless, ai-trust)|'
expect_fail auto-install-space "FAIL: README says opena2a installs" 's|^npm install -g opena2a-cli .*|npm install -g opena2a-cli      # Full suite (auto install HMA, Secretless, ai-trust)|'
expect_fail installs-automatically "FAIL: README says opena2a installs" 's|^npm install -g opena2a-cli .*|npm install -g opena2a-cli      # One CLI; installs the other tools automatically|'
expect_fail automatically-installs "FAIL: README says opena2a installs" 's|^brew install opena2a-org/tap/opena2a  .*|brew install opena2a-org/tap/opena2a   # One CLI; automatically installs HMA, Secretless, ai-trust|'
expect_fail pinned "FAIL: README says opena2a-cli pins" 's|are set by `opena2a-cli`|are pinned by `opena2a-cli`|'

if [ "$fail" -eq 0 ]; then
  echo "PASS: readme_test.sh passes README.md and fails all $cases edited copies"
fi
exit "$fail"
