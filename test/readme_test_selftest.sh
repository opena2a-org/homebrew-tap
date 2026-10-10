#!/usr/bin/env bash
# Runs test/readme_test.sh against README.md, which must pass; against edited
# copies of it that each break one rule, which must fail with that rule's
# message; against edited copies that stay correct, which must pass; and
# against paths that are not files, which must print one FAIL line.
# Run from anywhere: bash test/readme_test_selftest.sh
set -euo pipefail

cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail=0
cases=0
passes=0
paths=0

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

# expect_pass <name> <sed script>
expect_pass() {
  local name=$1 script=$2 copy="$tmp/$1.md" out
  passes=$((passes + 1))
  sed -e "$script" README.md > "$copy"
  if cmp -s README.md "$copy"; then
    echo "FAIL: $name: the edit did not change README.md"
    fail=1
  elif ! out=$(bash test/readme_test.sh "$copy"); then
    echo "FAIL: $name: readme_test.sh failed an edited README that is still correct:"
    echo "$out"
    fail=1
  fi
}

# expect_bad_path <name> <path>
expect_bad_path() {
  local name=$1 path=$2 out
  paths=$((paths + 1))
  if out=$(bash test/readme_test.sh "$path" 2>&1); then
    echo "FAIL: $name: readme_test.sh passed $path"
    fail=1
  elif [ "$out" != "FAIL: not a file: $path" ]; then
    echo "FAIL: $name: expected only \"FAIL: not a file: $path\", got:"
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
expect_fail chained-bare-install "$install" 's|^brew install opena2a-org/tap/opena2a$|brew install opena2a-org/tap/opena2a \&\& brew install hackmyagent|'
expect_fail upgrade-several "FAIL: brew upgrade names several formulae" 's|^brew upgrade opena2a .*|brew upgrade opena2a secretless-ai hackmyagent ai-trust|'
# The $a below is a sed command, not a shell expansion.
# shellcheck disable=SC2016
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
# The backticks below are Markdown, not command substitution.
# shellcheck disable=SC2016
expect_fail pinned "FAIL: README says opena2a-cli pins" 's|are set by `opena2a-cli`|are pinned by `opena2a-cli`|'

expect_pass comment-in-code-block '/^hackmyagent secure  *# Full security scan$/i\
# Run the scanner'
expect_pass chained-install 's|^brew install opena2a-org/tap/opena2a$|brew install opena2a-org/tap/opena2a \&\& opena2a --version|'
expect_pass chained-upgrade 's|^brew upgrade opena2a .*|brew upgrade opena2a; opena2a --version|'

expect_bad_path missing-file "$tmp/missing/README.md"
expect_bad_path directory "$tmp"

if [ "$fail" -eq 0 ]; then
  echo "PASS: readme_test.sh passes README.md and $passes correct edited copies, fails all $cases broken edited copies, and rejects $paths paths that are not files"
fi
exit "$fail"
