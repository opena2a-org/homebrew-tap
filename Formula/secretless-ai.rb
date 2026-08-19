class SecretlessAi < Formula
  desc "Keep secrets out of AI coding tools - works with Claude Code, Cursor, Copilot"
  homepage "https://github.com/opena2a-org/secretless-ai"
  url "https://registry.npmjs.org/secretless-ai/-/secretless-ai-0.23.0.tgz"
  sha256 "ab7d030a86fb0eb90abdd94155007dac20657dea035dfd9bf82e11fef929bd11"
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
