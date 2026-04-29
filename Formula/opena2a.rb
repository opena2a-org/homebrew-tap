class Opena2a < Formula
  desc "Security platform CLI for AI agents - scan, verify, and protect"
  homepage "https://opena2a.org"
  url "https://registry.npmjs.org/opena2a-cli/-/opena2a-cli-0.9.1.tgz"
  sha256 "729e6ffa9a0b7dd81a51fd1b548d357b3216587826b00fa71a2c393f3dc421aa"
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
