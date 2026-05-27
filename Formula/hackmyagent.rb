class Hackmyagent < Formula
  desc "Security scanner for AI agents - find vulnerabilities before attackers do"
  homepage "https://github.com/opena2a-org/hackmyagent"
  url "https://registry.npmjs.org/hackmyagent/-/hackmyagent-0.23.3.tgz"
  sha256 "d40fa308b85a4e29ae41836b9cf35aed71314451a0fc2cf3dc92e3eeba09c99f"
  license "Apache-2.0"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match "hackmyagent", shell_output("#{bin}/hackmyagent --version")
  end
end
