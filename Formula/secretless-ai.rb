class SecretlessAi < Formula
  desc "Keep secrets out of AI coding tools - works with Claude Code, Cursor, Copilot"
  homepage "https://github.com/opena2a-org/secretless-ai"
  url "https://registry.npmjs.org/secretless-ai/-/secretless-ai-0.14.0.tgz"
  sha256 "da5622ea5983015932fe62aeb3ed44fb6d2c5e7359c9432e44dabd49c7a9b06b"
  license "Apache-2.0"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match "Secretless", shell_output("#{bin}/secretless-ai --version")
  end
end
