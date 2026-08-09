class Hackmyagent < Formula
  desc "Security scanner for AI agents: static, semantic and adversarial analysis"
  homepage "https://github.com/opena2a-org/hackmyagent"
  url "https://registry.npmjs.org/hackmyagent/-/hackmyagent-0.28.0.tgz"
  sha256 "6474cbdd951accd0473451eb34b16aa8a53cee51596a0d0309809c857ce9df89"
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
