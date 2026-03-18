class AiTrust < Formula
  desc "Trust verification CLI for AI packages - check before you install"
  homepage "https://github.com/opena2a-org/ai-trust"
  url "https://registry.npmjs.org/ai-trust/-/ai-trust-0.2.3.tgz"
  sha256 "86217717818ed0f0309fae178b2329b310238b4151feaf913d9e6f14dd1bd87a"
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
