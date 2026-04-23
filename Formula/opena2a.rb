class Opena2a < Formula
  desc "Security platform CLI for AI agents - scan, verify, and protect"
  homepage "https://opena2a.org"
  url "https://registry.npmjs.org/opena2a-cli/-/opena2a-cli-0.8.25.tgz"
  sha256 "a3770c0e9eb9e0f9b7dfb671d0a40c5ca4b489190b10f5e6d53293771798ef01"
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
