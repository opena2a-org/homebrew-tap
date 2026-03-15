class Opena2a < Formula
  desc "Security platform CLI for AI agents - scan, verify, and protect"
  homepage "https://opena2a.org"
  url "https://registry.npmjs.org/opena2a-cli/-/opena2a-cli-0.6.3.tgz"
  sha256 "36921604a8e6c096cabf799bd7eb39f1855f1483c8fe84e096e2c725f43d88ae"
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
