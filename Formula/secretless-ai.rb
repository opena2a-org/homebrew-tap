class SecretlessAi < Formula
  desc "Keep secrets out of AI coding tools - works with Claude Code, Cursor, Copilot"
  homepage "https://github.com/opena2a-org/secretless-ai"
  url "https://registry.npmjs.org/secretless-ai/-/secretless-ai-0.21.3.tgz"
  sha256 "8ade1c2ecee883d276c2a7a799ae5de6245a40a4974212e320734f57ff4cc5de"
  license "Apache-2.0"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match "secretless-ai #{version}", shell_output("#{bin}/secretless-ai --version")
  end
end
