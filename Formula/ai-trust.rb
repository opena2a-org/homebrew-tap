class AiTrust < Formula
  desc "Trust verification CLI for AI packages - check before you install"
  homepage "https://github.com/opena2a-org/ai-trust"
  url "https://registry.npmjs.org/ai-trust/-/ai-trust-0.2.22.tgz"
  sha256 "6dba773fdad147961cbb464935f5c784951225ee7b362f0953c70710a21673a1"
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
