#!/usr/bin/env bash
# Checks README.md (or the file given as the first argument) against the
# formulae in this tap:
# - every command line that runs `brew install`, including indented lines and
#   `$ ` prompt lines in captured output, names each formula argument as
#   opena2a-org/tap/<formula> for a formula in Formula/, because current
#   Homebrew refuses a bare name from an untrusted third-party tap. Inline code
#   in prose is not checked;
# - no `brew upgrade` line names more than one formula: after the Quick Start
#   only opena2a is installed, and Homebrew refuses to load the others;
# - a section that runs hackmyagent, secretless-ai or ai-trust in a code block
#   names that formula's opena2a-org/tap/ install first, because installing
#   opena2a does not put those commands on PATH;
# - the Quick Start shows captured install and `opena2a --version` output for the
#   version Formula/opena2a.rb ships, before README line 30;
# - nothing claims that installing opena2a also installs the standalone tools.
# Run from anywhere: bash test/readme_test.sh [README]
set -euo pipefail

if [ $# -gt 0 ]; then
  readme="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
fi
cd "$(dirname "$0")/.."
readme=${readme:-$PWD/README.md}
fail=0

formulae=$(ls Formula | sed -n 's/\.rb$//p' | tr '\n' ' ')

bare=$(awk -v formulae="$formulae" '
  BEGIN { split(formulae, f, " "); for (i in f) known[f[i]] = 1 }
  /^[$[:space:]]*brew install / {
    args = $0
    sub(/#.*/, "", args)
    sub(/^[$[:space:]]*brew install /, "", args)
    n = split(args, a, /[[:space:]]+/)
    for (i = 1; i <= n; i++) {
      if (a[i] == "" || a[i] ~ /^-/) continue
      name = a[i]
      if (sub(/^opena2a-org\/tap\//, "", name) && (name in known)) continue
      print FNR ": " $0
      break
    }
  }' "$readme")
if [ -n "$bare" ]; then
  echo "FAIL: brew install of a formula not named opena2a-org/tap/<formula in Formula/>:"
  echo "$bare"
  fail=1
fi

upgrade=$(awk '
  /^[$[:space:]]*brew upgrade / {
    args = $0
    sub(/#.*/, "", args)
    sub(/^[$[:space:]]*brew upgrade /, "", args)
    n = split(args, a, /[[:space:]]+/)
    count = 0
    for (i = 1; i <= n; i++) if (a[i] != "" && a[i] !~ /^-/) count++
    if (count > 1) print FNR ": " $0
  }' "$readme")
if [ -n "$upgrade" ]; then
  echo "FAIL: brew upgrade names several formulae, which fails for any not installed:"
  echo "$upgrade"
  fail=1
fi

uninstalled=$(awk -v formulae="$formulae" '
  BEGIN { split(formulae, f, " "); for (i in f) if (f[i] != "opena2a") standalone[f[i]] = 1 }
  /^#+ / { section = $0; delete named }
  {
    line = $0
    while (match(line, /opena2a-org\/tap\/[a-z0-9-]+/)) {
      named[substr(line, RSTART + 16, RLENGTH - 16)] = 1
      line = substr(line, RSTART + RLENGTH)
    }
  }
  /^[[:space:]]*```/ { incode = !incode; next }
  incode {
    cmd = $0
    sub(/^[$[:space:]]*/, "", cmd)
    sub(/[[:space:]].*/, "", cmd)
    if ((cmd in standalone) && !(cmd in named)) print FNR ": " $0 "   (in " section ")"
  }' "$readme")
if [ -n "$uninstalled" ]; then
  echo "FAIL: section runs a standalone tool without naming its opena2a-org/tap/ install first:"
  echo "$uninstalled"
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

check_before_30 "brew install line" "$(grep -nF "/Cellar/opena2a/$version: " "$readme" | head -1 | cut -d: -f1)"
check_before_30 "opena2a --version line" "$(grep -nxF "opena2a $version" "$readme" | head -1 | cut -d: -f1)"

# Neither the formula nor `npm install -g opena2a-cli` puts hackmyagent,
# secretless-ai or ai-trust on PATH; they are private dependencies of opena2a.
autoinstall=$(grep -niE 'auto-?install' "$readme" || true)
if [ -n "$autoinstall" ]; then
  echo "FAIL: README says opena2a installs the standalone tools:"
  echo "$autoinstall"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: README install commands and captured output match opena2a $version"
fi
exit "$fail"
