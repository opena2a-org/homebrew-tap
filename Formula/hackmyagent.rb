class Hackmyagent < Formula
  desc "Security scanner for AI agents: static, semantic and adversarial analysis"
  homepage "https://github.com/opena2a-org/hackmyagent"
  url "https://registry.npmjs.org/hackmyagent/-/hackmyagent-0.26.0.tgz"
  sha256 "5a0834e6e6bb2721d6624f741241b227a8e1f8d83911a07470e133f3cd34c6dc"
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
