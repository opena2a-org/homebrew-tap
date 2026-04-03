class AiTrust < Formula
  desc "Trust verification CLI for AI packages - check before you install"
  homepage "https://github.com/opena2a-org/ai-trust"
  url "https://registry.npmjs.org/ai-trust/-/ai-trust-0.2.13.tgz"
  sha256 "74514148b3eec718632e79bf6c43a9c6e9548f2a3d3ba6ffc101ad2454f61cbe"
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
