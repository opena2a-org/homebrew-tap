class Opena2a < Formula
  desc "Security platform CLI for AI agents - scan, verify, and protect"
  homepage "https://opena2a.org"
  url "https://registry.npmjs.org/opena2a-cli/-/opena2a-cli-0.10.11.tgz"
  sha256 "14dea739b051a163eabeb720e9331a9020fb13f346910a9a255db3a90593dc63"
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
