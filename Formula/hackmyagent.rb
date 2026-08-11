class Hackmyagent < Formula
  desc "Security scanner for AI agents: static, semantic and adversarial analysis"
  homepage "https://github.com/opena2a-org/hackmyagent"
  url "https://registry.npmjs.org/hackmyagent/-/hackmyagent-0.30.0.tgz"
  sha256 "c9e93ece13c85451b762ddda10779c72ed883e419fce6eaab6269a3d8d51fd1c"
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
