class Opena2a < Formula
  desc "Security platform CLI for AI agents - scan, verify, and protect"
  homepage "https://opena2a.org"
  url "https://registry.npmjs.org/opena2a-cli/-/opena2a-cli-0.8.1.tgz"
  sha256 "d4aa2dd7aafbee2c78e358f07a8b123e763c3bf7a0eff91b0225bbdb39a7b30f"
  license "Apache-2.0"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match "opena2a", shell_output("#{bin}/opena2a --version")
  end
end
