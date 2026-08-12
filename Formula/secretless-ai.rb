class SecretlessAi < Formula
  desc "Keep secrets out of AI coding tools - works with Claude Code, Cursor, Copilot"
  homepage "https://github.com/opena2a-org/secretless-ai"
  url "https://registry.npmjs.org/secretless-ai/-/secretless-ai-0.22.0.tgz"
  sha256 "616b240ae8b2aa6e59536dff43b65d8f6a6cf0dd162b3f6e66e55a4266f5bd94"
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
