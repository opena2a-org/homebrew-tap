#!/usr/bin/env bash
# The single-quoted sed scripts below hold "$a" (a sed command) and Markdown
# backticks, neither of which is a shell expansion.
# shellcheck disable=SC2016
#
# Runs test/readme_test.sh against README.md, which must pass; against edited
# copies of it that each break one rule, which must fail with that rule's
# message; against edited copies that stay correct, which must pass; against
# paths that are not files, which must print one FAIL line; and against copies
# with one very long line added, which must get the right verdict in bounded
# processor time.
# Run from anywhere: bash test/readme_test_selftest.sh
set -euo pipefail

cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail=0
cases=0
passes=0
paths=0
long=0
# Processor seconds readme_test.sh may use on one README with a long line. The
# checks take time linear in the length of a line and finish in a fraction of
# this; a check that takes quadratic time needs several times as long.
limit=10

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

# expect_long_line <name> <expected message> <first words> <piece> <count> <last words>
# Adds one line to README.md: the first words, the piece <count> times, then
# the last words. readme_test.sh must print the expected message for that copy
# and use less than $limit seconds of processor time.
expect_long_line() {
  local name=$1 message=$2 first=$3 piece=$4 count=$5 last=$6 copy="$tmp/$1.md" out="$tmp/$1.out"
  local spent user sys ms TIMEFORMAT='%3U %3S'
  long=$((long + 1))
  {
    cat README.md
    awk -v first="$first" -v piece="$piece" -v count="$count" -v last="$last" 'BEGIN {
      printf "%s", first
      for (i = 0; i < count; i++) printf "%s", piece
      print last
    }'
  } > "$copy"
  spent=$( { time bash test/readme_test.sh "$copy" > "$out" 2>&1; } 2>&1 ) || true
  read -r user sys <<<"$spent"
  ms=$((10#${user//[!0-9]/} + 10#${sys//[!0-9]/}))
  if ! grep -qF "$message" "$out"; then
    echo "FAIL: $name: expected \"$message\", got:"
    head -1 "$out" | cut -c 1-200
    fail=1
  elif [ "$ms" -ge $((limit * 1000)) ]; then
    echo "FAIL: $name: readme_test.sh used $ms ms of processor time on a line of $count pieces, limit ${limit}000 ms"
    fail=1
  fi
}

install="FAIL: brew install of a formula"
upgrade="FAIL: brew upgrade names several formulae"
tab=$'\t'
expect_fail prompt-line "$install" 's|^\$ brew install opena2a-org/tap/opena2a$|$ brew install opena2a|'
expect_fail indented "$install" 's|^brew install opena2a-org/tap/hackmyagent .*|    brew install hackmyagent|'
expect_fail second-argument "$install" 's|^brew install opena2a-org/tap/opena2a$|brew install opena2a-org/tap/opena2a hackmyagent|'
expect_fail tap-name-in-comment "$install" 's|^brew install opena2a-org/tap/secretless-ai .*|brew install secretless-ai   # or brew install opena2a-org/tap/secretless-ai|'
expect_fail unknown-formula "$install" 's|^brew install opena2a-org/tap/ai-trust .*|brew install opena2a-org/tap/opena2a-cli|'
expect_fail chained-bare-install "$install" 's|^brew install opena2a-org/tap/opena2a$|brew install opena2a-org/tap/opena2a \&\& brew install hackmyagent|'
# A brew command that is not the first command on its line.
expect_fail install-after-and "$install" 's|^brew install opena2a-org/tap/opena2a$|cd /tmp \&\& brew install hackmyagent|'
expect_fail install-after-semicolon "$install" 's|^brew install opena2a-org/tap/opena2a$|brew update; brew install hackmyagent|'
expect_fail install-after-pipe "$install" 's#^brew install opena2a-org/tap/opena2a$#yes | brew install hackmyagent#'
# More than one space, or a tab, between brew and its subcommand.
expect_fail install-two-spaces "$install" 's|^brew install opena2a-org/tap/opena2a$|brew install opena2a-org/tap/opena2a \&\& brew  install hackmyagent|'
expect_fail install-tabs "$install" "s|^brew install opena2a-org/tap/opena2a\$|brew${tab}install${tab}hackmyagent|"
expect_fail upgrade-several "$upgrade" 's|^brew upgrade opena2a .*|brew upgrade opena2a secretless-ai hackmyagent ai-trust|'
expect_fail upgrade-two-commands "$upgrade" 's|^brew upgrade opena2a .*|brew upgrade opena2a; brew upgrade hackmyagent|'
expect_fail upgrade-after-and "$upgrade" 's|^brew upgrade opena2a .*|brew update \&\& brew upgrade opena2a hackmyagent|'
expect_fail upgrade-two-spaces "$upgrade" 's|^brew upgrade opena2a .*|brew  upgrade opena2a hackmyagent|'
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
expect_fail installed-automatically "FAIL: README says opena2a installs" '$a\
\
HackMyAgent, Secretless AI and ai-trust are installed automatically.'
# The dots of a version number do not end the sentence.
expect_fail version-numbers-in-sentence "FAIL: README says opena2a installs" '$a\
\
opena2a-cli 0.10.13 installs hackmyagent 0.25.2 automatically.'
# The other commands under a name other than "tools".
expect_fail installs-other-clis "FAIL: README says opena2a installs" '$a\
\
Installing opena2a automatically installs the other CLIs.'
expect_fail installs-commands "FAIL: README says opena2a installs" '$a\
\
The formula installs the standalone commands automatically.'
expect_fail installs-binaries "FAIL: README says opena2a installs" '$a\
\
The other binaries are installed automatically.'
# auto-install written with U+2010 to U+2015 in place of the hyphen.
code=2010
for dash in $'\342\200\220' $'\342\200\221' $'\342\200\222' $'\342\200\223' $'\342\200\224' $'\342\200\225'; do
  expect_fail "auto-install-u$code" "FAIL: README says opena2a installs" "\$a\\
\\
HMA is auto${dash}installed by the formula."
  code=$((code + 1))
done
expect_fail pinned "FAIL: README says opena2a-cli pins" 's|are set by `opena2a-cli`|are pinned by `opena2a-cli`|'

expect_pass comment-in-code-block '/^hackmyagent secure  *# Full security scan$/i\
# Run the scanner'
expect_pass chained-install 's|^brew install opena2a-org/tap/opena2a$|brew install opena2a-org/tap/opena2a \&\& opena2a --version|'
expect_pass install-after-and-tap-name 's|^brew install opena2a-org/tap/opena2a$|cd /tmp \&\& brew  install opena2a-org/tap/opena2a|'
expect_pass chained-upgrade 's|^brew upgrade opena2a .*|brew upgrade opena2a; opena2a --version|'
expect_pass upgrade-after-update 's|^brew upgrade opena2a .*|brew update \&\& brew upgrade opena2a|'
# "install" and "automatic" in a sentence that names no standalone tool.
expect_pass install-then-automatic-checks '$a\
\
Install the formula, then opena2a runs automatic checks.'
expect_pass automatic-install-of-dependencies '$a\
\
Homebrew runs an automatic install of the formula dependencies.'
# A "." that a blank follows still ends the sentence.
expect_pass install-and-automatic-in-two-sentences '$a\
\
Install the formula. HackMyAgent then runs automatic checks.'
# opena2a-cli is a package name, not the word CLI.
expect_pass package-name-is-not-cli '$a\
\
Install opena2a-cli, then opena2a runs automatic checks.'

expect_bad_path missing-file "$tmp/missing/README.md"
expect_bad_path directory "$tmp"

# The first two lines are read to their end: the bare name, or the second
# formula, is the last argument on them. The third names one formula
# throughout, so that copy still passes.
expect_long_line many-separators "$install" 'brew install opena2a-org/tap/opena2a' ';' 2000000 'brew install hackmyagent'
expect_long_line many-arguments "$upgrade" 'brew upgrade opena2a' ' --x' 1000000 ' hackmyagent'
expect_long_line many-tap-names "PASS: README install commands" '' 'opena2a-org/tap/opena2a ' 150000 ''

if [ "$fail" -eq 0 ]; then
  echo "PASS: readme_test.sh passes README.md and $passes correct edited copies, fails all $cases broken edited copies, rejects $paths paths that are not files, and checks $long long lines in under $limit s of processor time each"
fi
exit "$fail"
