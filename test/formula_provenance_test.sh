#!/usr/bin/env bash
# Checks each formula named on the command line, or each Formula/*.rb when
# none is named, against the npm registry for the version its url names:
# - the formula has one line that starts with url, mirror or head, and one
#   that starts with sha256, of the forms url "<url>" and sha256 "<hex>";
# - the url is the tarball url the registry gives for that version
#   (npm view <package>@<version> dist.tarball);
# - the tarball matches the integrity (sha512) the registry gives for that
#   version, and the formula's sha256 is the SHA-256 of that tarball;
# - npm audit signatures verifies the registry signature of that version and
#   lists a verified SLSA v1 provenance attestation for it, and the subject
#   alternative name of the certificate that signed the attestation names a
#   workflow file in a repository under https://github.com/opena2a-org.
# A url is downloaded only once it equals the registry's tarball url.
# Needs npm, node, curl, openssl and od, and access to registry.npmjs.org.
# The npm must print a "verified" list for
# npm audit signatures --json --include-attestations: npm 11.20.0 does,
# npm 10.9.2 does not. A lookup or download that fails is a FAIL, since the
# formula could not be checked.
# Run from anywhere: bash test/formula_provenance_test.sh [<formula> ...],
# where each formula is an absolute path or a path from the repository root.
set -euo pipefail

cd "$(dirname "$0")/.."
registry=https://registry.npmjs.org
owner=https://github.com/opena2a-org
provenance=https://slsa.dev/provenance/v1
fail=0
no_list=0

for tool in npm node curl openssl od; do
  if ! command -v "$tool" > /dev/null; then
    echo "FAIL: $tool is not on PATH"
    exit 1
  fi
done

if [ "$#" -eq 0 ]; then
  set -- Formula/*.rb
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Reads the report that npm audit signatures --json --include-attestations
# wrote for one package version and prints one line:
#   unreadable           the report is not JSON;
#   unverified <reason>  the report holds an error, or lists the version under
#                        invalid (a signature or attestation that does not
#                        verify) or missing (no registry signature);
#   no-list              the report has no "verified" list;
#   none                 the verified list holds no attestation of the version
#                        whose signed statement has the SLSA v1 provenance
#                        predicate type;
#   outside <name>       such an attestation was signed by a certificate whose
#                        subject alternative name is not a workflow file in a
#                        repository under the owner;
#   signed <name>        each such attestation was signed by one that is.
# npm 11.20.0 lists an attestation as verified only after it checks the
# Sigstore bundle and that the signed subject is this package version with
# the registry's integrity, so the certificate read here is one npm verified.
read_report='
const fs = require("fs");
const { X509Certificate } = require("crypto");
const [file, name, version, owner, predicateType] = process.argv.slice(1);
let report;
try {
  report = JSON.parse(fs.readFileSync(file, "utf8"));
} catch {
  console.log("unreadable");
  process.exit(0);
}
if (report.error) {
  console.log("unverified " + [report.error.code, report.error.summary].filter(Boolean).join(" "));
  process.exit(0);
}
const problems = [...(report.invalid || []), ...(report.missing || [])];
if (problems.length) {
  console.log("unverified " + (problems[0].message || "no registry signature"));
  process.exit(0);
}
if (!Array.isArray(report.verified)) {
  console.log("no-list");
  process.exit(0);
}
const entry = report.verified.find((v) => v.name === name && v.version === version);
const signers = [];
for (const attestation of (entry && entry.attestationBundles) || []) {
  let statement;
  try {
    statement = JSON.parse(Buffer.from(attestation.bundle.dsseEnvelope.payload, "base64").toString("utf8"));
  } catch {
    continue;
  }
  if (statement.predicateType !== predicateType) continue;
  let altName = "";
  try {
    const material = attestation.bundle.verificationMaterial;
    const raw = material.certificate ? material.certificate.rawBytes : material.x509CertificateChain.certificates[0].rawBytes;
    altName = new X509Certificate(Buffer.from(raw, "base64")).subjectAltName || "";
  } catch {
    altName = "";
  }
  signers.push(altName || "a certificate with no subject alternative name");
}
const prefix = "URI:" + owner + "/";
const workflow = /^[A-Za-z0-9._-]+\/\.github\/workflows\/[^\s,]+@refs\/[^\s,]+$/;
const inOwner = (s) => s.startsWith(prefix) && workflow.test(s.slice(prefix.length));
const outside = signers.find((s) => !inOwner(s));
if (!signers.length) console.log("none");
else if (outside !== undefined) console.log("outside " + outside);
else console.log("signed " + signers.join(" "));
'

n=0
for f in "$@"; do
  n=$((n + 1))
  if [ ! -f "$f" ] || [ ! -r "$f" ]; then
    echo "FAIL: cannot read: $f"
    fail=1
    continue
  fi

  # Count every line whose first word is url, mirror or head, each of which
  # names a source Homebrew can download, and every line whose first word is
  # sha256, so that a second source (a mirror, or a url in a resource block)
  # is not left unchecked.
  urls=$(grep -cE '^[[:space:]]*(url|mirror|head)([^A-Za-z0-9_.]|$)' "$f" || true)
  sums=$(grep -cE '^[[:space:]]*sha256([^A-Za-z0-9_.]|$)' "$f" || true)
  if [ "$urls" -ne 1 ] || [ "$sums" -ne 1 ]; then
    echo "FAIL: $f: lines that start with url, mirror or head: $urls; lines that start with sha256: $sums; this check reads a formula with one url line and one sha256 line"
    fail=1
    continue
  fi
  url=$(sed -nE 's|^[[:space:]]*url "([^"]*)"[[:space:]]*$|\1|p' "$f")
  sha256=$(sed -nE 's|^[[:space:]]*sha256 "([^"]*)"[[:space:]]*$|\1|p' "$f")
  if [ -z "$url" ] || [ -z "$sha256" ]; then
    echo "FAIL: $f has a url or sha256 line that is not of the form url \"<url>\" or sha256 \"<hex>\""
    fail=1
    continue
  fi

  # A registry tarball url is <registry>/<package>/-/<name>-<version>.tgz,
  # where <name> is the package name without an @scope/ in front of it.
  shape='^https://registry\.npmjs\.org/((@[a-z0-9][a-z0-9._-]*/)?([a-z0-9][a-z0-9._-]*))/-/([^/]+)\.tgz$'
  package=
  version=
  if [[ $url =~ $shape ]]; then
    package=${BASH_REMATCH[1]}
    name=${BASH_REMATCH[3]}
    file=${BASH_REMATCH[4]}
    case "$file" in
      "$name"-?*) version=${file#"$name"-} ;;
    esac
  fi
  if [ -z "$version" ]; then
    echo "FAIL: $f url $url is not an npm tarball url on $registry/"
    fail=1
    continue
  fi
  if ! tarball_url=$(npm view "$package@$version" dist.tarball --registry="$registry" 2> /dev/null) || [ -z "$tarball_url" ]; then
    echo "FAIL: could not read the tarball url of $package@$version from $registry"
    fail=1
    continue
  fi
  if [ "$url" != "$tarball_url" ]; then
    echo "FAIL: $f url is $url, but the registry gives $tarball_url as the tarball of $package@$version"
    fail=1
    continue
  fi

  tarball=$tmp/$n.tgz
  if ! curl -fsSL -o "$tarball" "$url"; then
    echo "FAIL: could not download $url"
    fail=1
  else
    if ! integrity=$(npm view "$package@$version" dist.integrity --registry="$registry" 2> /dev/null) || [ -z "$integrity" ]; then
      echo "FAIL: could not read the integrity of $package@$version from $registry"
      fail=1
    elif [ "sha512-$(openssl dgst -sha512 -binary "$tarball" | openssl base64 -A)" != "$integrity" ]; then
      echo "FAIL: $url does not match the integrity the registry gives for $package@$version"
      fail=1
    fi
    actual=$(openssl dgst -sha256 -binary "$tarball" | od -An -v -tx1 | tr -d ' \n')
    if [ "$sha256" != "$actual" ]; then
      echo "FAIL: $f has sha256 \"$sha256\", but $url has SHA-256 $actual"
      fail=1
    fi
  fi

  # npm audit signatures checks the packages a project depends on, so give it
  # a project whose only dependency is this version, with no other files.
  project=$tmp/project-$n
  mkdir -p "$project/node_modules/$package"
  printf '{"name":"formula-provenance-test","version":"0.0.0","private":true,"dependencies":{"%s":"%s"}}\n' "$package" "$version" > "$project/package.json"
  printf '{"name":"%s","version":"%s"}\n' "$package" "$version" > "$project/node_modules/$package/package.json"
  status=0
  (cd "$project" && npm audit signatures --json --include-attestations --registry="$registry" > report.json 2> /dev/null) || status=$?
  verdict=$(node -e "$read_report" "$project/report.json" "$package" "$version" "$owner" "$provenance") || verdict=
  case "$verdict" in
    unreadable)
      echo "FAIL: npm audit signatures printed no JSON report for $package@$version (exit status $status)"
      fail=1
      ;;
    "unverified "*)
      echo "FAIL: npm audit signatures does not verify $package@$version: ${verdict#unverified }"
      fail=1
      ;;
    no-list)
      if [ "$no_list" -eq 0 ]; then
        echo "FAIL: npm $(npm --version) printed no \"verified\" list for npm audit signatures --json --include-attestations, which this check reads (npm 11.20.0 prints one)"
      fi
      no_list=1
      fail=1
      ;;
    none)
      echo "FAIL: $f installs $package@$version, for which npm audit signatures lists no verified SLSA v1 provenance attestation"
      fail=1
      ;;
    "outside "*)
      echo "FAIL: $f installs $package@$version, whose provenance attestation was signed by ${verdict#outside }, not by a workflow file in a repository under $owner"
      fail=1
      ;;
    "signed "*)
      if [ "$status" -ne 0 ]; then
        echo "FAIL: npm audit signatures exited with status $status for $package@$version"
        fail=1
      fi
      ;;
    *)
      echo "FAIL: could not read the npm audit signatures report for $package@$version"
      fail=1
      ;;
  esac
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: each formula's url is the registry tarball of the version it names, its sha256 is that tarball's, and npm audit signatures verifies a SLSA v1 provenance attestation for that version signed by a workflow under $owner"
fi
exit "$fail"
