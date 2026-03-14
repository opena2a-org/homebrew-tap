class Hackmyagent < Formula
  desc "Security scanner for AI agents - find vulnerabilities before attackers do"
  homepage "https://github.com/opena2a-org/hackmyagent"
  url "https://registry.npmjs.org/hackmyagent/-/hackmyagent-0.10.1.tgz"
  sha256 "0bb287ab427c78fd6699f2db8eb1442b41d07016e5fa2ac3c86b67a262617edd"
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
