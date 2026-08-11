class Hackmyagent < Formula
  desc "Security scanner for AI agents: static, semantic and adversarial analysis"
  homepage "https://github.com/opena2a-org/hackmyagent"
  url "https://registry.npmjs.org/hackmyagent/-/hackmyagent-0.31.0.tgz"
  sha256 "cfe26745e6cb0d0aeb9ba40201d190059b296569135da05eccce7b5b87095822"
  license "Apache-2.0"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match "hackmyagent", shell_output("#{bin}/hackmyagent --version")
  end
end
