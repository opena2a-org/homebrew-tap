#!/usr/bin/env bash
# Checks README.md (or the file given as the first argument) against the
# formulae in this tap:
# - every `brew install` command in a fenced code block, including one on an
#   indented line, on a `$ ` prompt line in captured output, after another
#   command on the same line or after a prefix word such as sudo, VAR=value or
#   arch -arm64, names each formula argument as opena2a-org/tap/<formula> for
#   a formula in Formula/, because current Homebrew refuses a bare name from an
#   untrusted third-party tap. Outside fenced code blocks only a line whose
#   first word is brew is read, so inline code and other prose are not checked;
# - no line names more than one formula in its `brew upgrade` commands, read
#   the same way: after the Quick Start only opena2a is installed, and Homebrew
#   refuses to load the others;
# - a section that runs hackmyagent, secretless-ai or ai-trust in a code block
#   names that formula's opena2a-org/tap/ install first, because installing
#   opena2a does not put those commands on PATH;
# - the Quick Start shows captured install and `opena2a --version` output for the
#   version Formula/opena2a.rb ships, before README line 30;
# - nothing claims that installing opena2a also installs the standalone tools;
# - nothing calls the copies opena2a-cli bundles pinned.
# A FAIL that names README lines prints each as "<line>: <text>".
# Run from anywhere: bash test/readme_test.sh [README]
set -euo pipefail

# Every tool below reads the README one byte at a time, so a byte that is not
# valid UTF-8 gets a verdict instead of an error from awk or tr.
export LC_ALL=C

# Every check reads the README through text, which turns each NUL byte into a
# space: the awk macOS ships ends a line at a NUL, grep reads a file with one
# as binary, and bash drops one from the output of a command.
text() {
  tr '\000' ' ' < "$readme"
}

if [ $# -gt 0 ]; then
  if [ ! -f "$1" ]; then
    echo "FAIL: not a file: $1"
    exit 1
  fi
  readme="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
fi
cd "$(dirname "$0")/.."
readme=${readme:-$PWD/README.md}
fail=0

formulae=
for f in Formula/*.rb; do
  f=${f#Formula/}
  formulae+="${f%.rb} "
done

# Both brew checks read a line as commands when it is in a fenced code block,
# or, outside one, when its first word is brew, so a line that starts with
# prose or inline code is not read. A command line is split into commands at
# ;, &, &&, | and ||, a shell comment (a # at the start of the line or after a
# blank or separator) is dropped, and arguments are read from every command
# that runs brew install or brew upgrade, also after prefix words such as
# sudo, VAR=value or arch -arm64, however many blanks separate its words.
# `brew install opena2a-org/tap/opena2a && opena2a --version` is one install
# of one formula, and `cd /tmp && brew  install hackmyagent` is an install of a
# bare name. Flags, redirections such as 2>&1 or 2>log, and the word after a
# redirection that stands alone (> log) are not formula arguments.
#
# They read the README through commands, which turns & and | into ; and every
# NUL, tab, carriage return, form feed, vertical tab and no-break space
# (U+00A0) into a space, and leaves the line numbers as they are. awk then
# splits a line at one character only (";", or a run of spaces). Splitting at
# a regular expression takes time quadratic in the number of pieces in the awk
# macOS ships, so one line with a million separators or arguments took tens of
# seconds to check. numbered prints the README lines that the line numbers on
# its input name.
commands() {
  text | tr '&|\t\r\f\v' ';;    ' | sed "s/$(printf '\302\240')/ /g"
}

numbered() {
  awk 'BEGIN { while ((getline n < "-") > 0) want[n] = 1 } FNR in want { print FNR ": " $0 }' <(text)
}

# brew_lines <install|upgrade> prints the number of every line with a
# brew install command that names a formula not as
# opena2a-org/tap/<formula in Formula/>, or every line whose brew upgrade
# commands name more than one formula. A formula named twice, or once with and
# once without opena2a-org/tap/, counts once.
brew_lines() {
  commands | awk -v verb="$1" -v formulae="$formulae" '
    BEGIN {
      split(formulae, f, " "); for (i in f) known[f[i]] = 1
      command = "(^|[$ ])brew +" verb " "
    }
    /^ *```/ { incode = !incode; next }
    {
      line = $0
      if (!incode && line !~ /^[$ ]*brew /) next
      if (line !~ "brew +" verb " ") next
      sub(/(^|[ ;])#.*/, "", line)
      m = split(line, cmds, ";")
      bad = count = 0
      delete seen
      for (c = 1; c <= m && !bad; c++) {
        if (!match(cmds[c], command)) continue
        n = split(substr(cmds[c], RSTART + RLENGTH), a, " ")
        for (i = 1; i <= n; i++) {
          if (a[i] ~ /^-/) continue
          if (a[i] ~ /^[0-9]*[<>]/) {
            if (a[i] ~ /^[0-9]*[<>]+$/) i++
            continue
          }
          name = a[i]
          tapped = sub(/^opena2a-org\/tap\//, "", name)
          if (verb == "install" && !(tapped && (name in known))) {
            bad = 1
            break
          }
          if (!(name in seen)) count++
          seen[name] = 1
        }
      }
      if (bad || (verb == "upgrade" && count > 1)) print FNR
    }' | numbered
}

bare=$(brew_lines install)
if [ -n "$bare" ]; then
  echo "FAIL: brew install of a formula not named opena2a-org/tap/<formula in Formula/>:"
  echo "$bare"
  fail=1
fi

# The formulae are counted over the whole line, so `brew upgrade opena2a;
# brew upgrade hackmyagent` names two.
upgrade=$(brew_lines upgrade)
if [ -n "$upgrade" ]; then
  echo "FAIL: brew upgrade names several formulae, which fails for any not installed:"
  echo "$upgrade"
  fail=1
fi

uninstalled=$(text | awk -v formulae="$formulae" '
  BEGIN { split(formulae, f, " "); for (i in f) if (f[i] != "opena2a") standalone[f[i]] = 1 }
  # A "# comment" line inside a fenced block is shell, not a heading.
  !incode && /^#+ / { section = $0; delete named }
  # Every opena2a-org/tap/<name> on the line, read from the pieces between "/"
  # so that the time stays linear in the number of names: <name> starts the
  # piece after a "tap" piece that follows a piece ending in opena2a-org. A
  # name that fills its piece is not also the opena2a-org of a later name.
  {
    n = split($0, part, "/")
    for (i = 3; i <= n; i++) {
      if (part[i - 1] != "tap" || part[i - 2] !~ /opena2a-org$/) continue
      if (!match(part[i], /^[a-z0-9-]+/)) continue
      named[substr(part[i], 1, RLENGTH)] = 1
      if (RLENGTH == length(part[i])) i += 2
    }
  }
  /^[[:space:]]*```/ { incode = !incode; next }
  incode {
    cmd = $0
    sub(/^[$[:space:]]*/, "", cmd)
    sub(/[[:space:]].*/, "", cmd)
    if ((cmd in standalone) && !(cmd in named)) print FNR ": " $0 "   (in " section ")"
  }')
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

# The carriage returns of a README with CRLF line ends are dropped before a
# whole line is compared.
check_before_30 "brew install line" "$(text | grep -nF "/Cellar/opena2a/$version: " | head -1 | cut -d: -f1)"
check_before_30 "opena2a --version line" "$(text | tr -d '\r' | grep -nxF "opena2a $version" | head -1 | cut -d: -f1)"

# Neither the formula nor `npm install -g opena2a-cli` puts hackmyagent,
# secretless-ai or ai-trust on PATH; they are private dependencies of opena2a.
# Catches auto-install, autoinstall and auto install, also when the hyphen is
# one of U+2010 to U+2015, and a sentence that says "install" and
# "automatic", in either order, and also names a standalone tool or the tools
# as a group: "tools", "CLIs", "commands" or "binaries", or "tool", "CLI",
# "command" or "binary" after "other", "standalone" or "individual". A sentence
# with "install" and "automatic" that names none of them passes, such as
# "Install the CLI, then opena2a runs automatic checks.", "The opena2a binary
# is installed automatically." or one whose only "cli" is the package name
# opena2a-cli.
#
# A sentence ends at a "." that a blank or the end of the line follows, so the
# dots in "0.10.13" do not end one. The line is split at every "." and the
# pieces of one sentence are read in turn, each one able to set the install,
# automatic and named flags of the sentence, which is how "automatically, as
# of 0.10.13, installs hackmyagent" is seen across the dots.
dashes=$(printf '\342\200\220|\342\200\221|\342\200\222|\342\200\223|\342\200\224|\342\200\225')
autoinstall=$(text | awk -v dashes="$dashes" '
  BEGIN { auto = "auto([-[:space:]]|" dashes ")?install" }
  {
    line = tolower($0)
    if (line ~ auto) { print FNR ": " $0; next }
    n = split(line, part, ".")
    installs = automatic = named = 0
    for (i = 1; i <= n; i++) {
      p = part[i]
      if (p ~ /install/) installs = 1
      if (p ~ /automatic/) automatic = 1
      if (p ~ /tools|binaries|hma|hackmyagent|secretless|ai-trust/ ||
          p ~ /(^|[^a-z])commands|(^|[^a-z0-9-])clis([^a-z0-9]|$)/ ||
          p ~ /(other|standalone|individual)[[:space:]]+(tool|cli|command|binary)([^a-z0-9]|$)/) named = 1
      if (i < n && part[i + 1] !~ /^[[:space:]]/ && !(i + 1 == n && part[n] == "")) continue
      if (installs && automatic && named) { print FNR ": " $0; next }
      installs = automatic = named = 0
    }
  }')
if [ -n "$autoinstall" ]; then
  echo "FAIL: README says opena2a installs the standalone tools:"
  echo "$autoinstall"
  fail=1
fi

# opena2a-cli gives some of its bundled tools as version ranges, not exact
# versions, so its copies are not pinned.
pinned=$(text | awk 'tolower($0) ~ /bundle.*pinned|pinned.*bundle/ { print FNR ": " $0 }')
if [ -n "$pinned" ]; then
  echo "FAIL: README says opena2a-cli pins its bundled tools:"
  echo "$pinned"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: README install commands and captured output match opena2a $version"
fi
exit "$fail"
