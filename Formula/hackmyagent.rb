class Hackmyagent < Formula
  desc "Security scanner for AI agents: static, semantic and adversarial analysis"
  homepage "https://github.com/opena2a-org/hackmyagent"
  url "https://registry.npmjs.org/hackmyagent/-/hackmyagent-0.26.1.tgz"
  sha256 "9ebbd7288e9aadc8a8edd8f55f12f17e0206f1f5010616ba458e98519b8a4fed"
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
