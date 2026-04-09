class Hackmyagent < Formula
  desc "Security scanner for AI agents - find vulnerabilities before attackers do"
  homepage "https://github.com/opena2a-org/hackmyagent"
  url "https://registry.npmjs.org/hackmyagent/-/hackmyagent-0.15.7.tgz"
  sha256 "4b0edc9f0bbf937e7473410c5f3a010aa83cb702da53702c7438075b12acba3e"
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
