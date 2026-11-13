#!/usr/bin/env bash
# Runs test/formula_provenance_test.sh on a copy of Formula/ai-trust.rb, which
# must pass, and on planted formulae that each break one thing the check
# verifies, which must fail with exactly the one FAIL line for that thing:
# - a sha256 that differs from the tarball's in its first hex digit;
# - a url on a host whose name starts with registry.npmjs.org, and a url on
#   registry.npmjs.org over http;
# - a registry url whose file name gives the version as <version>+build, for
#   which the registry's tarball url is the one of <version>;
# - a second url and sha256, in a resource block;
# - a mirror line and a head line;
# - a url line that quotes its url with single quotes;
# - a version published without a provenance attestation (ai-trust 0.2.25);
# - a version whose provenance attestation was signed by a workflow outside
#   https://github.com/opena2a-org (sigstore 5.0.1).
# The planted formulae for ai-trust 0.2.25 and sigstore 5.0.1 carry the
# SHA-256 of those tarballs, so that provenance is the one thing they break.
# Needs what test/formula_provenance_test.sh needs.
# Run from anywhere: bash test/formula_provenance_test_selftest.sh
set -euo pipefail

cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail=0
cases=0
owner=https://github.com/opena2a-org

url=$(sed -nE 's|^[[:space:]]*url "([^"]*)".*|\1|p' Formula/ai-trust.rb)
right=$(sed -nE 's|^[[:space:]]*sha256 "([^"]*)".*|\1|p' Formula/ai-trust.rb)
path=${url#https://registry.npmjs.org/}
file=${url##*/}
version=${file#ai-trust-}
version=${version%.tgz}
case "${right:0:1}" in
  0) wrong=1${right:1} ;;
  *) wrong=0${right:1} ;;
esac

# formula <name> <url> <sha256> [<line> ...] writes $tmp/<name>.rb, a formula
# that installs the tarball at the url, with the lines added before its end.
formula() {
  local name=$1 source=$2 sum=$3 line
  shift 3
  {
    echo 'class Planted < Formula'
    echo '  desc "Formula planted by formula_provenance_test_selftest.sh"'
    echo '  homepage "https://github.com/opena2a-org/homebrew-tap"'
    echo "  url \"$source\""
    echo "  sha256 \"$sum\""
    echo '  license "Apache-2.0"'
    echo
    echo '  depends_on "node"'
    echo
    echo '  def install'
    echo '    system "npm", "install", *std_npm_args'
    echo '  end'
    for line in "$@"; do
      echo "$line"
    done
    echo 'end'
  } > "$tmp/$name.rb"
}

# expect <name> <output> runs the check on $tmp/<name>.rb and records a FAIL
# unless it exits with status 1 and prints exactly the output.
expect() {
  local got status=0
  cases=$((cases + 1))
  got=$(bash test/formula_provenance_test.sh "$tmp/$1.rb" 2>&1) || status=$?
  if [ "$status" -ne 1 ] || [ "$got" != "$2" ]; then
    echo "FAIL: $1: expected exit status 1 and this output:"
    printf '%s\n' "$2"
    echo "but got exit status $status and this output:"
    printf '%s\n' "$got"
    fail=1
  fi
}

cp Formula/ai-trust.rb "$tmp/copy.rb"
status=0
got=$(bash test/formula_provenance_test.sh "$tmp/copy.rb" 2>&1) || status=$?
if [ "$status" -ne 0 ] || [ "$(printf '%s\n' "$got" | grep -c '')" -ne 1 ] || [ "${got#PASS: }" = "$got" ]; then
  echo "FAIL: copy of Formula/ai-trust.rb: expected exit status 0 and one PASS line, but got exit status $status and this output:"
  printf '%s\n' "$got"
  fail=1
fi

formula wrong-sha256 "$url" "$wrong"
expect wrong-sha256 "FAIL: $tmp/wrong-sha256.rb has sha256 \"$wrong\", but $url has SHA-256 $right"

other_host=https://registry.npmjs.org.example.com/$path
formula other-host "$other_host" "$right"
expect other-host "FAIL: $tmp/other-host.rb url $other_host is not an npm tarball url on https://registry.npmjs.org/"

plain_http=http://registry.npmjs.org/$path
formula plain-http "$plain_http" "$right"
expect plain-http "FAIL: $tmp/plain-http.rb url $plain_http is not an npm tarball url on https://registry.npmjs.org/"

build=${url%.tgz}+build.tgz
formula build-version "$build" "$right"
expect build-version "FAIL: $tmp/build-version.rb url is $build, but the registry gives $url as the tarball of ai-trust@$version+build"

formula two-urls "$url" "$right" \
  '' \
  '  resource "extra" do' \
  '    url "https://example.com/extra-1.0.0.tgz"' \
  "    sha256 \"$right\"" \
  '  end'
expect two-urls "FAIL: $tmp/two-urls.rb: lines that start with url, mirror or head: 2; lines that start with sha256: 2; this check reads a formula with one url line and one sha256 line"

formula mirror-and-head "$url" "$right" \
  '  mirror "https://example.com/ai-trust.tgz"' \
  '  head "https://github.com/opena2a-org/ai-trust.git", branch: "main"'
expect mirror-and-head "FAIL: $tmp/mirror-and-head.rb: lines that start with url, mirror or head: 3; lines that start with sha256: 1; this check reads a formula with one url line and one sha256 line"

formula single-quotes "$url" "$right"
sed -e "s|^  url \"\\(.*\\)\"\$|  url '\\1'|" "$tmp/single-quotes.rb" > "$tmp/edited.rb"
mv "$tmp/edited.rb" "$tmp/single-quotes.rb"
expect single-quotes "FAIL: $tmp/single-quotes.rb has a url or sha256 line that is not of the form url \"<url>\" or sha256 \"<hex>\""

formula no-provenance https://registry.npmjs.org/ai-trust/-/ai-trust-0.2.25.tgz \
  f7de7fc2aac754660db467a07e9b7440ec2208f120cbb496ef60e0a709bae9ca
expect no-provenance "FAIL: $tmp/no-provenance.rb installs ai-trust@0.2.25, for which npm audit signatures lists no verified SLSA v1 provenance attestation"

formula other-signer https://registry.npmjs.org/sigstore/-/sigstore-5.0.1.tgz \
  1da1912b5e6a8c09ee5132384bf7d9a5a1fa9ac905ad215d50edffe1939c8ccd
expect other-signer "FAIL: $tmp/other-signer.rb installs sigstore@5.0.1, whose provenance attestation was signed by URI:https://github.com/sigstore/sigstore-js/.github/workflows/release.yml@refs/heads/main, not by a workflow file in a repository under $owner"

if [ "$fail" -eq 0 ]; then
  echo "PASS: formula_provenance_test.sh passes a copy of Formula/ai-trust.rb and fails all $cases planted formulae, each with the one FAIL line for what it breaks"
fi
exit "$fail"
