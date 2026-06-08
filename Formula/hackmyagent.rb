class Hackmyagent < Formula
  desc "Security scanner for AI agents - find vulnerabilities before attackers do"
  homepage "https://github.com/opena2a-org/hackmyagent"
  url "https://registry.npmjs.org/hackmyagent/-/hackmyagent-0.23.10.tgz"
  sha256 "3057bd26ee496896850f030608d16e523457ed9c786413ed0afb477f6bd67dfb"
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
