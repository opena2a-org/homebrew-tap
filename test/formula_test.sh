#!/usr/bin/env bash
# Checks each formula in Formula/ against the npm registry:
# - the version in its registry.npmjs.org url is the one
#   `npm view <package> version` prints;
# - the tarball that url serves matches the integrity (sha512) npm publishes
#   for that version, and the formula's sha256 is the SHA-256 of that tarball.
# Needs npm, curl, openssl and access to registry.npmjs.org. A lookup or
# download that fails is a FAIL, since the formula could not be checked.
# Run from anywhere: bash test/formula_test.sh
set -euo pipefail

cd "$(dirname "$0")/.."
registry=https://registry.npmjs.org
fail=0

for tool in npm curl openssl od; do
  if ! command -v "$tool" > /dev/null; then
    echo "FAIL: $tool is not on PATH"
    exit 1
  fi
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for f in Formula/*.rb; do
  url=$(sed -nE 's|^[[:space:]]*url "(https://registry\.npmjs\.org/[^"]+\.tgz)".*|\1|p' "$f" | sed -n 1p)
  sha256=$(sed -nE 's|^[[:space:]]*sha256 "([^"]*)".*|\1|p' "$f" | sed -n 1p)
  if [ -z "$url" ]; then
    echo "FAIL: $f has no registry.npmjs.org tarball url"
    fail=1
    continue
  fi
  # The url is <registry>/<package>/-/<name>-<version>.tgz, where <name> is
  # the package name without an @scope/ in front of it.
  package=${url#"$registry"/}
  package=${package%%/-/*}
  file=${url##*/}
  version=${file#"${package##*/}"-}
  version=${version%.tgz}

  if ! latest=$(npm view "$package" version --registry="$registry" 2> /dev/null) || [ -z "$latest" ]; then
    echo "FAIL: could not read the version of $package from $registry"
    fail=1
  elif [ "$version" != "$latest" ]; then
    echo "FAIL: $f installs $package $version, but npm view $package version prints $latest"
    fail=1
  fi

  tarball=$tmp/$file
  if ! curl -fsSL -o "$tarball" "$url"; then
    echo "FAIL: could not download $url"
    fail=1
    continue
  fi
  if ! integrity=$(npm view "$package@$version" dist.integrity --registry="$registry" 2> /dev/null) || [ -z "$integrity" ]; then
    echo "FAIL: could not read the integrity of $package@$version from $registry"
    fail=1
  elif [ "sha512-$(openssl dgst -sha512 -binary "$tarball" | openssl base64 -A)" != "$integrity" ]; then
    echo "FAIL: $url does not match the integrity npm publishes for $package@$version"
    fail=1
  fi
  actual=$(openssl dgst -sha256 -binary "$tarball" | od -An -v -tx1 | tr -d ' \n')
  if [ "$sha256" != "$actual" ]; then
    echo "FAIL: $f has sha256 \"$sha256\", but $url has SHA-256 $actual"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: each formula installs the version npm view prints for its package, and its sha256 is that tarball's"
fi
exit "$fail"
