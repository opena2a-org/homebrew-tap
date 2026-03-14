class AiTrust < Formula
  desc "Trust verification CLI for AI packages - check before you install"
  homepage "https://github.com/opena2a-org/ai-trust"
  url "https://registry.npmjs.org/ai-trust/-/ai-trust-0.1.2.tgz"
  sha256 "b5d6db2c7f8763800268ca21e2a6742ed4d87e6b3d2c9979f88c5c573fdc34e2"
  license "Apache-2.0"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match "ai-trust", shell_output("#{bin}/ai-trust --help")
  end
end
