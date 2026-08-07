class SecretlessAi < Formula
  desc "Keep secrets out of AI coding tools - works with Claude Code, Cursor, Copilot"
  homepage "https://github.com/opena2a-org/secretless-ai"
  url "https://registry.npmjs.org/secretless-ai/-/secretless-ai-0.21.2.tgz"
  sha256 "d9b428a904a76fd3b6bc715fef0db8f659bee7b7dbfc10acccef9fed3e0f9f49"
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
