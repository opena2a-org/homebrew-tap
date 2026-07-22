class SecretlessAi < Formula
  desc "Keep secrets out of AI coding tools - works with Claude Code, Cursor, Copilot"
  homepage "https://github.com/opena2a-org/secretless-ai"
  url "https://registry.npmjs.org/secretless-ai/-/secretless-ai-0.20.0.tgz"
  sha256 "282aa65c3b2e7801fb1ac23b0855e5dd8927a34947fe16a4b7934ebdeba678f1"
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
