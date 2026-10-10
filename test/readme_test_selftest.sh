#!/usr/bin/env bash
# The single-quoted sed scripts below hold "$a" (a sed command) and Markdown
# backticks, neither of which is a shell expansion.
# shellcheck disable=SC2016
#
# Runs test/readme_test.sh against README.md, which must pass; against edited
# copies of it that each break one rule, which must fail with that rule's
# message and name the edited line by its number and text; against edited
# copies that stay correct, which must pass; against paths that are not files,
# which must print one FAIL line; and against copies with one very long line
# added, which must get the right verdict in bounded processor time.
# readme_test.sh runs under a UTF-8 locale where the system has one, as it does
# for most users.
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
utf8=$(locale -a 2>/dev/null | grep -ixE 'c\.utf-?8|en_us\.utf-?8' | head -1 || true)
# The edits below write bytes that are not valid UTF-8.
export LC_ALL=C

check() {
  LC_ALL=$utf8 bash test/readme_test.sh "$@"
}

# edit <sed script> <copy> writes README.md edited by the script to the copy.
# A \001 byte in the script stands for a NUL byte, which a shell argument
# cannot hold.
edit() {
  sed -e "$1" README.md | tr '\001' '\000' > "$2"
}

# reported_lines <copy> <output> succeeds when every "<line>: <text>" line of
# the output names a line of the copy and starts with that line's text, and at
# least one of them names a line that the edit changed or added. A NUL byte in
# the copy is read as a space, as readme_test.sh prints it.
reported_lines() {
  awk '
    FNR == 1 { file++ }
    file == 1 { orig[FNR] = $0; next }
    file == 2 { copy[FNR] = $0; lines = FNR; next }
    match($0, /^[0-9]+: /) {
      n = substr($0, 1, RLENGTH - 2) + 0
      if (n < 1 || n > lines || substr($0, RLENGTH + 1, length(copy[n])) != copy[n]) { bad = 1; exit }
      if (!(n in orig) || orig[n] != copy[n]) changed = 1
    }
    END { exit bad || !changed }' README.md <(tr '\000' ' ' < "$1") "$2"
}

if ! out=$(check README.md); then
  echo "FAIL: README.md itself does not pass:"
  echo "$out"
  fail=1
fi

# expect_fail <name> <expected FAIL message> <sed script>
expect_fail() {
  local name=$1 message=$2 script=$3 copy="$tmp/$1.md" out="$tmp/$1.out"
  cases=$((cases + 1))
  edit "$script" "$copy"
  if cmp -s README.md "$copy"; then
    echo "FAIL: $name: the edit did not change README.md"
    fail=1
  elif check "$copy" > "$out" 2>&1; then
    echo "FAIL: $name: readme_test.sh passed an edited README"
    fail=1
  elif ! grep -aqF "$message" "$out"; then
    echo "FAIL: $name: expected \"$message\", got:"
    cat "$out"
    fail=1
  elif ! reported_lines "$copy" "$out"; then
    echo "FAIL: $name: expected the edited line as \"<line>: <text>\", got:"
    cat "$out"
    fail=1
  fi
}

# expect_pass <name> <sed script>
# The copy must pass, and the only output must be the PASS line.
expect_pass() {
  local name=$1 script=$2 copy="$tmp/$1.md" out
  passes=$((passes + 1))
  edit "$script" "$copy"
  if cmp -s README.md "$copy"; then
    echo "FAIL: $name: the edit did not change README.md"
    fail=1
  elif ! out=$(check "$copy" 2>&1); then
    echo "FAIL: $name: readme_test.sh failed an edited README that is still correct:"
    echo "$out"
    fail=1
  elif [[ $out != "PASS: "* || $out == *$'\n'* ]]; then
    echo "FAIL: $name: expected only the PASS line, got:"
    echo "$out"
    fail=1
  fi
}

# expect_bad_path <name> <path>
expect_bad_path() {
  local name=$1 path=$2 out
  paths=$((paths + 1))
  if out=$(check "$path" 2>&1); then
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
# the last words. readme_test.sh must print the expected message for that copy,
# name the added line when the message is a FAIL, and use less than $limit
# seconds of processor time.
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
  spent=$( { time check "$copy" > "$out" 2>&1; } 2>&1 ) || true
  read -r user sys <<<"$spent"
  ms=$((10#0${user//[!0-9]/} + 10#0${sys//[!0-9]/}))
  if ! grep -qF "$message" "$out"; then
    echo "FAIL: $name: expected \"$message\", got:"
    head -1 "$out" | cut -c 1-200
    fail=1
  elif [[ $message == FAIL* ]] && ! reported_lines "$copy" "$out"; then
    echo "FAIL: $name: expected the added line as \"<line>: <text>\", got:"
    head -2 "$out" | cut -c 1-200
    fail=1
  elif [ "$ms" -ge $((limit * 1000)) ]; then
    echo "FAIL: $name: readme_test.sh used $ms ms of processor time on a line of $count pieces, limit ${limit}000 ms"
    fail=1
  fi
}

install="FAIL: brew install of a formula"
upgrade="FAIL: brew upgrade names several formulae"
tab=$'\t'
cr=$'\r'
nbsp=$'\302\240'
nul=$'\001'
invalid=$'\377'
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
# The only brew install on its line, with two spaces after brew.
expect_fail install-after-and-two-spaces "$install" 's|^brew install opena2a-org/tap/opena2a$|cd /tmp \&\& brew  install hackmyagent|'
# A no-break space or a NUL byte between brew and install.
expect_fail install-no-break-space "$install" "s|^brew install opena2a-org/tap/opena2a\$|brew${nbsp}install hackmyagent|"
expect_fail install-nul "$install" "s|^brew install opena2a-org/tap/opena2a\$|brew${nul}install hackmyagent|"
# A word before brew.
expect_fail install-after-sudo "$install" 's|^brew install opena2a-org/tap/opena2a$|sudo brew install hackmyagent|'
expect_fail install-after-variable "$install" 's|^brew install opena2a-org/tap/opena2a$|HOMEBREW_NO_AUTO_UPDATE=1 brew install hackmyagent|'
expect_fail install-after-arch "$install" 's|^brew install opena2a-org/tap/opena2a$|arch -arm64 brew install hackmyagent|'
# A # inside a word does not start a comment.
expect_fail install-after-hash-in-url "$install" 's|^brew install opena2a-org/tap/opena2a$|curl -fsSL https://example.com/#a \&\& brew install hackmyagent|'
# A line outside code blocks whose first word is brew.
expect_fail install-line-outside-code "$install" '$a\
\
brew install hackmyagent'
# A byte that is not valid UTF-8 on the line.
expect_fail install-invalid-byte "$install" "s|^brew install opena2a-org/tap/opena2a\$|brew install hackmyagent ${invalid}|"
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
# opena2a-org/tap/opena2a-org/tap/hackmyagent names opena2a-org, not
# hackmyagent.
expect_fail standalone-doubled-tap-name "FAIL: section runs a standalone tool" '$a\
\
## Scan\
\
See opena2a-org/tap/opena2a-org/tap/hackmyagent.\
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
expect_fail installs-standalone-cli "FAIL: README says opena2a installs" '$a\
\
Installing opena2a automatically installs each standalone CLI.'
# "automatic" before "install", across the dots of a version number.
expect_fail automatically-then-installs "FAIL: README says opena2a installs" '$a\
\
automatically, as of 0.10.13, installs hackmyagent.'
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
# One formula named twice, a flag, and a redirection are not several formulae.
expect_pass upgrade-same-formula-twice 's|^brew upgrade opena2a .*|brew upgrade opena2a \&\& brew upgrade opena2a|'
expect_pass upgrade-same-formula-tap-name 's|^brew upgrade opena2a .*|brew upgrade opena2a; brew upgrade opena2a-org/tap/opena2a|'
expect_pass upgrade-flag 's|^brew upgrade opena2a .*|brew upgrade --greedy opena2a|'
expect_pass upgrade-redirect 's#^brew upgrade opena2a .*#brew upgrade opena2a 2>\&1 | tail -1#'
expect_pass install-redirect 's#^brew install opena2a-org/tap/opena2a$#brew install opena2a-org/tap/opena2a 2>\&1 | tee log#'
expect_pass install-redirect-to-file 's|^brew install opena2a-org/tap/opena2a$|brew install opena2a-org/tap/opena2a > install.log|'
# Inline code and other prose are not commands.
expect_pass install-in-inline-code '$a\
\
Use `brew tap opena2a-org/tap && brew install opena2a-org/tap/opena2a` to install.'
expect_pass install-in-prose-after-semicolon '$a\
\
Use the full name; brew install opena2a alone is refused.'
# CRLF line ends, and a byte that is not valid UTF-8 or a NUL byte in prose.
expect_pass crlf "s/\$/${cr}/"
expect_pass invalid-byte-in-prose "\$a\\
\\
A byte that is not UTF-8: ${invalid}."
expect_pass nul-in-prose "\$a\\
\\
A NUL byte: ${nul}."
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
# The single opena2a CLI, command or binary is not the standalone tools.
expect_pass install-the-cli '$a\
\
Install the CLI, then opena2a runs automatic checks.'
expect_pass opena2a-command-installed-automatically '$a\
\
Homebrew installs the opena2a command and links it automatically.'
expect_pass opena2a-binary-installed-automatically '$a\
\
The opena2a binary is installed automatically by the formula.'

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
