class Hackmyagent < Formula
  desc "Security scanner for AI agents - find vulnerabilities before attackers do"
  homepage "https://github.com/opena2a-org/hackmyagent"
  url "https://registry.npmjs.org/hackmyagent/-/hackmyagent-0.12.3.tgz"
  sha256 "ae6aec8905545c00d7a7c96259419f5bb3f255ec169713c91c580d965c39c228"
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
