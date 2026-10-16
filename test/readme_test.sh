#!/usr/bin/env bash
# Checks README.md (or the file given as the first argument) against the
# formulae in this tap:
# - every `brew install` command in a fenced code block names each formula
#   argument as opena2a-org/tap/<formula> for a formula in Formula/, because
#   current Homebrew refuses a bare name from an untrusted third-party tap. A
#   placeholder such as <formula> is a formula argument, so it fails. A
#   command is read at the start of a line, on a `$ ` prompt line in captured
#   output, after a separator such as &&, |, ( or $( and after prefix words
#   such as sudo, VAR=value or arch -arm64, also when brew is named by its
#   path or the command goes on after a backslash at the end of a line. A
#   brew in the middle of a sentence of captured output ("To install it, run:
#   brew install opena2a") is not read. Outside fenced code blocks only a line
#   whose first word is brew, also after a `$ ` prompt, is read, so inline
#   code and other prose are not checked;
# - no line names more than one formula in its `brew upgrade` commands, read
#   the same way: after the Quick Start only opena2a is installed, and Homebrew
#   refuses to load the others;
# - a section that runs hackmyagent, secretless-ai or ai-trust in a code block
#   names that formula's opena2a-org/tap/ install first, because installing
#   opena2a does not put those commands on PATH;
# - the Quick Start shows the captured `$ brew install opena2a-org/tap/opena2a`
#   and `$ opena2a --version` lines before README line 30, and each line of
#   that capture other than a `...` elision is in the capture on the capture
#   page, in the same order. The capture page is docs/captures/quick-start.md,
#   or the file given as the second argument, and a capture is the first fenced
#   code block with a line that starts with `$ `;
# - the capture page shows captured install and `opena2a --version` output for
#   the version Formula/opena2a.rb ships;
# - nothing claims that installing opena2a also installs the standalone tools;
# - nothing calls the copies opena2a-cli bundles pinned;
# - no line states a count of a tool's checks, controls or payloads, which
#   changes with each release of that tool and which nothing here reads: the
#   README points to the tool's --help, and docs/formulae.md keeps the counts
#   it once carried;
# - a number of CLIs or formulae the README states is the number of formula
#   files in Formula/;
# - each npm package the README installs or links is one that a formula in
#   Formula/ installs (the package in its registry.npmjs.org url): each
#   package argument of an npm install command, or of one of its aliases such
#   as npm i, read as brew install is read and with any @<version> dropped,
#   and the package in each npmjs.com/package/<name> link. On a line that
#   links the file of one formula, as a row of the Formulae table does, a
#   link names the package that formula installs. The links are read
#   against the formula files, not fetched.
# A fenced code block opens at a line of three or more ` or ~, also indented
# or in a block quote, and closes at a line of at least as many of the same
# character. An indented code block and an HTML <pre> block are read as
# prose, and formula names that brew reads from standard input, as through
# xargs, are not read.
# A FAIL that names README lines prints each as "<line>: <text>".
# Run from anywhere: bash test/readme_test.sh [README [CAPTURE PAGE]]
set -euo pipefail

# Every tool below reads the README one byte at a time, so a byte that is not
# valid UTF-8 gets a verdict instead of an error from awk or tr.
export LC_ALL=C

# raw turns each NUL byte of the README into a space: the awk macOS ships ends
# a line at a NUL, grep reads a file with one as binary, and bash drops one
# from the output of a command. Every check reads the README through text,
# which also turns each no-break space (U+00A0) into a space, so that every
# check sees one as a blank. A FAIL prints README lines from raw. Given a
# file, raw and text read that file instead, as the capture page checks do.
nbsp=$(printf '\302\240')
raw() {
  tr '\000' ' ' < "${1:-$readme}"
}

text() {
  raw "$@" | sed "s/$nbsp/ /g"
}

# readable <path> ends the run with one FAIL line unless the path is a file
# the user can read.
readable() {
  if [ ! -f "$1" ]; then
    echo "FAIL: not a file: $1"
    exit 1
  fi
  if [ ! -r "$1" ]; then
    echo "FAIL: cannot read: $1"
    exit 1
  fi
}

if [ $# -gt 0 ]; then
  readable "$1"
  readme="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
fi
if [ $# -gt 1 ]; then
  readable "$2"
  page="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
  pagename=$2
fi
cd "$(dirname "$0")/.."
readme=${readme:-$PWD/README.md}
if [ -z "${page:-}" ]; then
  pagename=docs/captures/quick-start.md
  readable "$pagename"
  page=$PWD/$pagename
fi
fail=0

formulae=
shipped=0
# packages lists the npm package each formula downloads, read from the first
# registry.npmjs.org url in its file, and installs pairs each formula with it
# as <formula>=<package>.
packages=
installs=
for f in Formula/*.rb; do
  package=$(sed -nE 's|^[[:space:]]*url "https://registry\.npmjs\.org/(.+)/-/[^/"]+\.tgz".*|\1|p' "$f" | sed -n 1p)
  f=${f#Formula/}
  formulae+="${f%.rb} "
  shipped=$((shipped + 1))
  if [ -n "$package" ]; then
    packages+="$package "
    installs+="${f%.rb}=$package "
  fi
done

# fenced is awk source for the checks that read code blocks. scan(line) reads
# the next README line and sets incode to 1 while the line is in a fenced code
# block, isfence to 1 when the line opens or closes one, and body to the line
# without the block quote markers (>) in front of it. A fence that opens in a
# block quote ends with the block quote, and a line in a block that did not
# open in one keeps its >, which can be captured output. A ``` line that holds
# another ` is inline code, not a fence. The backticks below are awk, not a
# shell expansion.
# shellcheck disable=SC2016
fenced='
  function scan(s,    q, run, rest) {
    isfence = 0
    q = match(s, /^( *>)+/)
    if (incode && quoted && !q) incode = 0
    if (q && (!incode || quoted)) {
      s = substr(s, RLENGTH + 1)
      sub(/^ /, "", s)
    }
    body = s
    if (!match(s, /^[[:space:]]*(```+|~~~+)/)) return
    run = substr(s, RSTART, RLENGTH)
    rest = substr(s, RSTART + RLENGTH)
    sub(/^[[:space:]]*/, "", run)
    if (!incode) {
      if (run ~ /^`/ && index(rest, "`")) return
      incode = isfence = 1
      mark = substr(run, 1, 1)
      size = length(run)
      quoted = q > 0
    } else if (substr(run, 1, 1) == mark && length(run) >= size && rest ~ /^[[:space:]]*$/) {
      incode = 0
      isfence = 1
    }
  }
'

# Both brew checks read a line as commands when it is in a fenced code block,
# or, outside one, when its first word is brew, also after a `$ ` prompt or as
# a path such as /opt/homebrew/bin/brew, so a line that starts with prose or
# inline code is not read. The npm install check reads npm the same way, and
# also skips the flags between npm and install (npm -g install x); a flag
# value given as the next word (--prefix dir) is read as a package, so it
# fails, and npx is not read. A shell comment (a # at the start of a line or
# after a blank or separator) is dropped from each line, and a line that then
# ends with a backslash continues on the next one. The command line is split
# into commands at ;, &, &&, |, ||, (, ) and `, so (brew install x),
# $(brew install x) and `brew install x` each hold one. A command runs brew
# when its first word is brew, or a path that ends in /brew, after any prefix
# words: a `$ ` prompt, VAR=value, a word in prefix below such as sudo, env,
# arch or xargs, the flags after one and the value after a flag (sudo -u
# admin, arch -arm64), or a shell word such as if, then, do, ! or {. A brew
# after any other word is prose, as in captured output that reads "To install
# it, run: brew install opena2a". Arguments are read from every command that
# runs brew install or brew upgrade, however many blanks separate its words.
# `brew install opena2a-org/tap/opena2a && opena2a --version` is one install
# of one formula, and `cd /tmp && brew  install hackmyagent` is an install of a
# bare name. Flags, redirections such as 2>&1, &>log or 2>log, and the word
# after a redirection that stands alone (> log) are not formula arguments; a
# placeholder such as <formula> is.
#
# They read the README through commands, which rewrites a redirection to a
# file descriptor (2>&1, >&2, 2>&-) as >-, and &>, >& and >| as >, so the & or
# | in one does not split the command it is part of. It then turns &, |, ( and
# ) into ; and every tab, carriage return, form feed and vertical tab into a
# space, as text has done for NUL and U+00A0, and leaves the line numbers as
# they are. awk then splits a line at one character only (";", "`", or a run
# of spaces). Splitting at a regular expression takes time quadratic in the
# number of pieces in the awk macOS ships, so one line with a million
# separators or arguments took tens of seconds to check.
commands() {
  text | sed -E 's/[<>]&([0-9]+-?|-)/>-/g; s/>&/>/g; s/&>/>/g; s/>[|]/>/g' | tr '&|()\t\r\f\v' ';;;;    '
}

# numbered reads README line numbers, one per line of its input and each one
# optionally followed by more text, and prints each line they name as
# "<line>: <text>" followed by that text. With no line numbers it does not
# read the README.
numbered() {
  awk '
    BEGIN {
      while ((getline l < "-") > 0) { n = l + 0; sub(/^[0-9]*/, "", l); want[n] = l; lines++ }
      if (!lines) exit
    }
    FNR in want { print FNR ": " $0 want[FNR] }' <(raw)
}

# command_lines <brew|npm> <verbs> <names> prints the number of every line of
# a command line with a brew install command that names a formula not as
# opena2a-org/tap/<formula in Formula/>, with an npm install command that
# names a package no formula in Formula/ installs, or of a command line whose
# brew upgrade commands name more than one formula. <verbs> is the subcommand
# and its aliases, separated by |, and <names> the formulae or packages it may
# name. A command line is one README line, or several when a backslash ends
# each one but the last. A formula named twice, or once with and once without
# opena2a-org/tap/, counts once.
command_lines() {
  commands | awk -v tool="$1" -v verb="$2" -v names="$3" "$fenced"'
    BEGIN {
      split(names, f, " "); for (i in f) known[f[i]] = 1
      split("sudo doas env command exec nohup time nice arch caffeinate xargs if then else elif do while until ! {", p, " ")
      for (i in p) prefix[p[i]] = 1
      runner = "(^|/)" tool "$"
      verbs = "^(" verb ")$"
      lead = "^[$ ]*([^ ;]*/)?" tool " "
      named = tool " +" (tool == "npm" ? "(-[^ ;]* +)*" : "") "(" verb ")"
    }
    # run reads the command whose words are a[1..cnt].
    function run(a, cnt,    i, j, runs, flags, name, tapped) {
      if (bad) return
      runs = flags = 0
      for (i = 1; i <= cnt; i++) {
        if (a[i] ~ runner) { runs = 1; break }
        if (i == 1 && a[i] == "$") continue
        if (a[i] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) continue
        if (a[i] in prefix) { flags = 1; continue }
        if (flags && (a[i] ~ /^-/ || a[i - 1] ~ /^-/)) continue
        break
      }
      if (tool == "npm") while (i < cnt && a[i + 1] ~ /^-/) i++
      if (!runs || i >= cnt || a[i + 1] !~ verbs) return
      for (j = i + 2; j <= cnt; j++) {
        if (a[j] ~ /^-/) continue
        if (a[j] !~ /^<[^<>]+>$/ && a[j] ~ /^[0-9]*[<>]/) {
          if (a[j] ~ /^[0-9]*[<>]+$/) j++
          continue
        }
        name = a[j]
        if (tool == "npm") {
          match(name, /^@?[^@]*/)
          if (!(substr(name, 1, RLENGTH) in known)) {
            bad = 1
            return
          }
          continue
        }
        tapped = sub(/^opena2a-org\/tap\//, "", name)
        if (verb == "install" && !(tapped && (name in known))) {
          bad = 1
          return
        }
        if (!(name in seen)) count++
        seen[name] = 1
      }
    }
    # feed reads the commands on one line; a ` or ; ends a command. When cont
    # is 1 the line ended in a backslash, so its last command goes on to the
    # next line: its words are kept in w[1..n] until the command ends, which
    # keeps the time linear in the length of a command line continued over
    # many lines. When glue is 1 the line before ended in a backslash right
    # after a word, and a word that starts this line continues that word, as
    # it does in the shell.
    function feed(line, glue, cont,    b, nb, k, cmds, m, c, x, nx, i, open) {
      glue = glue && n && line ~ /^[^ ;`]/
      nb = split(line, b, "`")
      for (k = 1; k <= nb; k++) {
        m = split(b[k], cmds, ";")
        for (c = 1; c <= m; c++) {
          nx = split(cmds[c], x, " ")
          open = cont && k == nb && c == m
          if (!n && !open) {
            if (nx) run(x, nx)
            continue
          }
          for (i = 1; i <= nx; i++) {
            if (glue) w[n] = w[n] x[i]
            else w[++n] = x[i]
            glue = 0
          }
          if (!open) {
            run(w, n)
            n = 0
          }
        }
      }
    }
    # finish reads a command that the last line read left open and prints the
    # number of each line of the command line when it fails.
    function finish(last,    i) {
      if (n) run(w, n)
      n = 0
      if (bad || (verb == "upgrade" && count > 1)) for (i = first; i <= last; i++) print i
    }
    {
      scan($0)
      if (isfence) {
        if (held) finish(FNR - 1)
        held = 0
        next
      }
      line = body
      sub(/(^|[ ;])#.*/, "", line)
      glue = held && !after
      if (!held) {
        if (!incode && line !~ lead) next
        first = FNR
        bad = count = n = 0
        split("", seen)
      }
      cont = sub(/\\ *$/, "", line)
      if (line != "") after = line ~ / $/
      if (held || cont || line ~ named) feed(line, glue, cont)
      held = cont
      if (!held) finish(FNR)
    }
    END { if (held) finish(FNR) }' | numbered
}

bare=$(command_lines brew install "$formulae")
if [ -n "$bare" ]; then
  echo "FAIL: brew install of a formula not named opena2a-org/tap/<formula in Formula/>:"
  echo "$bare"
  fail=1
fi

# The formulae are counted over the whole command line, so `brew upgrade
# opena2a; brew upgrade hackmyagent` names two.
upgrade=$(command_lines brew upgrade "$formulae")
if [ -n "$upgrade" ]; then
  echo "FAIL: brew upgrade names several formulae, which fails for any not installed:"
  echo "$upgrade"
  fail=1
fi

# The aliases are the ones `npm install --help` lists.
npm=$(command_lines npm 'install|add|i|in|ins|inst|insta|instal|isnt|isnta|isntal|isntall' "$packages")
if [ -n "$npm" ]; then
  echo "FAIL: npm install of a package no formula in Formula/ installs:"
  echo "$npm"
  fail=1
fi

# linked reads the pieces between "/" on each line, so that the time stays
# linear in its length: a link names <name> in the piece after a "package"
# piece that follows a piece ending in npmjs.com, or @<scope>/<name> in that
# piece and the next, and what follows the name, such as /v/<version>, is not
# read. A formula file is <formula>.rb at the start of the piece after one
# ending in Formula. Each line it fails is followed by the formula on it and
# the package that formula installs, or by the linked package no formula
# installs.
linked=$(text | awk -v installs="$installs" '
  BEGIN {
    n = split(installs, pair, " ")
    for (i = 1; i <= n; i++) {
      eq = index(pair[i], "=")
      package[substr(pair[i], 1, eq - 1)] = substr(pair[i], eq + 1)
      known[substr(pair[i], eq + 1)] = 1
    }
  }
  {
    n = split($0, part, "/")
    links = files = 0
    split("", file)
    for (i = 2; i <= n; i++) {
      if (part[i - 1] ~ /(^|[^[:alnum:]_-])Formula$/ && match(part[i], /^[[:alnum:]@._+-]+\.rb/)) {
        f = substr(part[i], 1, RLENGTH - 3)
        if (!(f in file)) files++
        file[f] = 1
        last = f
      }
      if (i < 3 || part[i - 1] != "package" || part[i - 2] !~ /(^|[^[:alnum:]_-])npmjs\.com$/) continue
      name = part[i]
      if (name ~ /^@/) name = (i < n) ? name "/" part[i + 1] : ""
      match(name, /^@?[[:alnum:]._~-]+(\/[[:alnum:]._~-]+)?/)
      link[++links] = substr(name, 1, RLENGTH)
    }
    row = files == 1 && (last in package)
    for (i = 1; i <= links; i++) {
      if (row && link[i] != package[last]) {
        print FNR "   (Formula/" last ".rb installs " package[last] ")"
        break
      }
      if (!row && !(link[i] in known)) {
        print FNR "   (no formula in Formula/ installs " link[i] ")"
        break
      }
    }
  }' | numbered)
if [ -n "$linked" ]; then
  echo "FAIL: npmjs.com link to a package other than the one a formula in Formula/ installs:"
  echo "$linked"
  fail=1
fi

uninstalled=$(text | awk -v formulae="$formulae" "$fenced"'
  BEGIN { split(formulae, f, " "); for (i in f) if (f[i] != "opena2a") standalone[f[i]] = 1 }
  { scan($0) }
  # A "# comment" line inside a fenced block is shell, not a heading.
  !incode && !isfence && /^#+ / { section = $0; delete named }
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
  isfence { next }
  incode {
    cmd = body
    sub(/^[$[:space:]]*/, "", cmd)
    sub(/[[:space:]].*/, "", cmd)
    if ((cmd in standalone) && !(cmd in named)) print FNR "   (in " section ")"
  }' | numbered)
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
    echo "FAIL: README has no captured $label"
    fail=1
  elif [ "$line" -ge 30 ]; then
    echo "FAIL: captured $label is not before README line 30:"
    echo "$line" | numbered
    fail=1
  fi
}

# check_on_page <label> <grep options> <pattern> fails unless a line of the
# capture page matches the pattern.
check_on_page() {
  if ! text "$page" | tr -d '\r' | grep "$2" -- "$3" > /dev/null; then
    echo "FAIL: $pagename has no captured $1 for opena2a $version"
    fail=1
  fi
}

# The carriage returns of a file with CRLF line ends are dropped before a
# whole line is compared.
check_before_30 "brew install line" "$(text | tr -d '\r' | grep -nxF '$ brew install opena2a-org/tap/opena2a' | head -1 | cut -d: -f1)"
check_before_30 "opena2a --version line" "$(text | tr -d '\r' | grep -nxF '$ opena2a --version' | head -1 | cut -d: -f1)"
check_on_page "brew install line" -F "/Cellar/opena2a/$version: "
check_on_page "opena2a --version line" -xF "opena2a $version"

# The README capture trims the capture on the capture page: its lines, less
# each `...` elision line, are lines of the page capture in the same order.
# trimmed prints the number of each README capture line that is not, read
# from the page capture past the line the README line before it matched. A
# fence left open runs to the end of its file.
trimmed=$(awk "$fenced"'
  function finish(    k) {
    if (prompt && !(file in have)) {
      have[file] = 1
      for (k = 1; k <= cnt; k++) {
        if (file == 1) { readme[k] = cur[k]; line[k] = at[k] } else capture[k] = cur[k]
      }
      if (file == 1) lines = cnt; else captured = cnt
    }
    cnt = prompt = 0
  }
  FILENAME != name {
    if (name != "") finish()
    name = FILENAME
    file = (FILENAME == ARGV[1]) ? 1 : 2
    incode = 0
  }
  {
    scan($0)
    if (isfence) { if (!incode) finish(); next }
    if (!incode) next
    cur[++cnt] = body
    at[cnt] = FNR
    if (body ~ /^\$ /) prompt = 1
  }
  END {
    finish()
    for (i = 1; i <= lines; i++) {
      if (readme[i] == "...") continue
      for (k = j + 1; k <= captured && capture[k] != readme[i]; k++) ;
      if (k <= captured) j = k; else print line[i]
    }
  }' <(text | tr -d '\r') <(text "$page" | tr -d '\r') | numbered)
if [ -n "$trimmed" ]; then
  echo "FAIL: README capture shows lines the capture on $pagename does not hold in that order:"
  echo "$trimmed"
  fail=1
fi

# Neither the formula nor `npm install -g opena2a-cli` puts hackmyagent,
# secretless-ai or ai-trust on PATH; they are private dependencies of opena2a.
# Catches auto-install, autoinstall and auto install, also when the hyphen is
# one of U+2010 to U+2015, and a sentence that says "install" and
# "automatic", in either order, and also names a standalone tool or the tools
# as a group: "tools", "CLIs", "commands" or "binaries", or "tool", "CLI",
# "command" or "binary" after "other", "standalone", "individual", "each",
# "every" or "all" ("another tool" is not one of them). A sentence with
# "install" and "automatic" that names none of them passes, such as "Install
# the CLI, then opena2a runs automatic checks.", "The opena2a binary is
# installed automatically." or one whose only "cli" is the package name
# opena2a-cli.
#
# Two kinds of words are dropped before any of this is read. An "install" or
# "auto" right after "not", "n't", "never" or "no longer" (and an optional
# "be") denies the claim, so "opena2a does not install hackmyagent
# automatically." and "HackMyAgent is not auto-installed." pass. "you
# install", "you have installed" and "you've installed" are an install the
# reader does, not opena2a installing anything, so "Homebrew updates
# hackmyagent automatically after you install it." passes.
#
# A sentence ends at a "." that a blank or the end of the line follows, so the
# dots in "0.10.13" do not end one. The line is split at every "." and the
# pieces of one sentence are read in turn, each one able to set the install,
# automatic and named flags of the sentence, which is how "automatically, as
# of 0.10.13, installs hackmyagent" is seen across the dots.
dashes=$(printf '\342\200\220|\342\200\221|\342\200\222|\342\200\223|\342\200\224|\342\200\225')
apostrophe="('|$(printf '\342\200\231'))"
negated="(not|n${apostrophe}t|never|no[[:space:]]+longer)[[:space:]]+(be[[:space:]]+)?(auto|install)"
reader="you(${apostrophe}ve|[[:space:]]+have)?[[:space:]]+install"
# sed drops both kinds before awk reads the line: gsub in the awk macOS ships
# takes time quadratic in the number of matches on a line.
autoinstall=$(text | tr '[:upper:]' '[:lower:]' | sed -E "s/$negated/ /g; s/$reader/ /g" | awk -v dashes="$dashes" '
  BEGIN { auto = "auto([-[:space:]]|" dashes ")?install" }
  {
    line = $0
    if (line ~ auto) { print FNR; next }
    n = split(line, part, ".")
    installs = automatic = named = 0
    for (i = 1; i <= n; i++) {
      p = part[i]
      if (p ~ /install/) installs = 1
      if (p ~ /automatic/) automatic = 1
      if (p ~ /tools|binaries|hma|hackmyagent|secretless|ai-trust/ ||
          p ~ /(^|[^a-z])commands|(^|[^a-z0-9-])clis([^a-z0-9]|$)/ ||
          p ~ /(^|[^a-z])(other|standalone|individual|each|every|all)[[:space:]]+(tool|cli|command|binary)([^a-z0-9]|$)/) named = 1
      if (i < n && part[i + 1] !~ /^[[:space:]]/ && !(i + 1 == n && part[n] == "")) continue
      if (installs && automatic && named) { print FNR; next }
      installs = automatic = named = 0
    }
  }' | numbered)
if [ -n "$autoinstall" ]; then
  echo "FAIL: README says opena2a installs the standalone tools:"
  echo "$autoinstall"
  fail=1
fi

# opena2a-cli gives some of its bundled tools as version ranges, not exact
# versions, so its copies are not pinned.
pinned=$(text | awk 'tolower($0) ~ /bundle.*pinned|pinned.*bundle/ { print FNR }' | numbered)
if [ -n "$pinned" ]; then
  echo "FAIL: README says opena2a-cli pins its bundled tools:"
  echo "$pinned"
  fail=1
fi

# A count of a tool's checks, controls or payloads is a number, up to three
# words, then "checks", "controls" or "payloads", or a number joined by "-" to
# one of those words, as in "323 checks", "72 behavioral governance controls"
# or "72-control". A number right after a letter, digit, ".", "," or "-" is
# not read, so neither the parts of a version such as 0.32.0 nor the 2 of
# OASB-2 is a count.
word='[[:space:]]+[a-z][a-z-]*'
counts=$(text | tr '[:upper:]' '[:lower:]' | awk -v word="$word" '
  BEGIN {
    count = "(^|[^0-9a-z.,-])[0-9][0-9,]*(" word ")?(" word ")?(" word ")?"
    count = count "([[:space:]]+(checks|controls|payloads)|-(checks?|controls?|payloads?))([^a-z]|$)"
  }
  $0 ~ count { print FNR }' | numbered)
if [ -n "$counts" ]; then
  echo "FAIL: README states a count of a tool's checks, controls or payloads, which changes with its releases:"
  echo "$counts"
  fail=1
fi

# A number of CLIs or formulae, in digits or as a word from one to twelve,
# right before "CLIs", "formulae" or "formulas", as in "Four CLIs", must be
# the number of formula files in Formula/.
miscounted=$(text | tr '[:upper:]' '[:lower:]' |
  { grep -n -o -E '[[:alnum:]]+[[:space:]]+(clis|formulae|formulas)([^[:alnum:]]|$)' || true; } |
  awk -v shipped="$shipped" '
    BEGIN {
      split("one two three four five six seven eight nine ten eleven twelve", name, " ")
      for (i = 1; i <= 12; i++) value[name[i]] = i
    }
    {
      colon = index($0, ":")
      number = substr($0, colon + 1)
      sub(/[[:space:]].*/, "", number)
      if (number ~ /^[0-9]+$/) number += 0
      else if (number in value) number = value[number]
      else next
      if (number != shipped) print substr($0, 1, colon - 1)
    }' | sort -un | numbered)
if [ -n "$miscounted" ]; then
  echo "FAIL: README counts CLIs or formulae other than the $shipped formula files in Formula/:"
  echo "$miscounted"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: README install commands and captured output match opena2a $version"
fi
exit "$fail"
