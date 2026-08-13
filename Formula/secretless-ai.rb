class SecretlessAi < Formula
  desc "Keep secrets out of AI coding tools - works with Claude Code, Cursor, Copilot"
  homepage "https://github.com/opena2a-org/secretless-ai"
  url "https://registry.npmjs.org/secretless-ai/-/secretless-ai-0.22.1.tgz"
  sha256 "dd34271af3229999c68429d26fb6f6dc8d6ad897c8f592d73c1f031be2370f18"
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
