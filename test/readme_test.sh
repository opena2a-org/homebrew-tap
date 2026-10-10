#!/usr/bin/env bash
# Checks README.md against the formulae in this tap:
# - every `brew install` names the tap, because current Homebrew refuses a bare
#   name from an untrusted third-party tap;
# - the Quick Start shows captured install and `opena2a --version` output for the
#   version Formula/opena2a.rb ships, before README line 30;
# - nothing claims that installing opena2a also installs the standalone tools.
# Run from anywhere: bash test/readme_test.sh
set -euo pipefail

cd "$(dirname "$0")/.."
fail=0

bare=$(grep -nE '^brew install ' README.md | grep -v 'brew install opena2a-org/tap/' || true)
if [ -n "$bare" ]; then
  echo "FAIL: brew install without the opena2a-org/tap/ prefix:"
  echo "$bare"
  fail=1
fi

version=$(sed -nE 's|.*/opena2a-cli-([0-9][0-9.]*)\.tgz".*|\1|p' Formula/opena2a.rb)
if [ -z "$version" ]; then
  echo "FAIL: could not read the opena2a version from Formula/opena2a.rb"
  exit 1
fi

check_before_30() {
  local label=$1 line=$2
  if [ -z "$line" ]; then
    echo "FAIL: README has no captured $label for opena2a $version"
    fail=1
  elif [ "$line" -ge 30 ]; then
    echo "FAIL: captured $label for opena2a $version is on README line $line, not before line 30"
    fail=1
  fi
}

check_before_30 "brew install line" "$(grep -nF "/Cellar/opena2a/$version: " README.md | head -1 | cut -d: -f1)"
check_before_30 "opena2a --version line" "$(grep -nxF "opena2a $version" README.md | head -1 | cut -d: -f1)"

# Neither the formula nor `npm install -g opena2a-cli` puts hackmyagent,
# secretless-ai or ai-trust on PATH; they are private dependencies of opena2a.
autoinstall=$(grep -niE 'auto-?install' README.md || true)
if [ -n "$autoinstall" ]; then
  echo "FAIL: README says opena2a installs the standalone tools:"
  echo "$autoinstall"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: README install commands and captured output match opena2a $version"
fi
exit "$fail"
