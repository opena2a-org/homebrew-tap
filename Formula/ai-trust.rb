class AiTrust < Formula
  desc "Trust verification CLI for AI packages - check before you install"
  homepage "https://github.com/opena2a-org/ai-trust"
  url "https://registry.npmjs.org/ai-trust/-/ai-trust-0.2.0.tgz"
  sha256 "f22f60ce87d232cb52be0f8f828da987a4a33d7cb866d9f51abaef8c47334d25"
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
