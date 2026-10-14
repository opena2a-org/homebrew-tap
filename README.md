# OpenA2A Homebrew Tap

[![Status: stable](https://img.shields.io/badge/status-stable-green)](STATUS.md)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

> **[OpenA2A](https://github.com/opena2a-org)**: [CLI](https://github.com/opena2a-org/opena2a) · [HackMyAgent](https://github.com/opena2a-org/hackmyagent) · [Secretless](https://github.com/opena2a-org/secretless-ai) · [AIM](https://github.com/opena2a-org/agent-identity-management) · [Browser Guard](https://github.com/opena2a-org/ai-browserguard) · [DVAA](https://github.com/opena2a-org/damn-vulnerable-ai-agent)

[Website](https://opena2a.org) · [Docs](https://opena2a.org/cli) · [Discord](https://discord.gg/uRZa3KXgEn)

Install the OpenA2A security tools with Homebrew. Four CLIs that protect AI agent ecosystems -- scan for vulnerabilities, keep secrets out of AI context, verify trust, and enforce behavioral governance.

## Quick Start

```bash
brew install opena2a-org/tap/opena2a   # One CLI; bundles HMA, Secretless, ai-trust
opena2a --version
```

What `brew install opena2a-org/tap/opena2a` and `opena2a --version` print on Linux, trimmed ([capture details](docs/captures/quick-start.md)); the Cellar path differs on macOS:

```text
$ brew install opena2a-org/tap/opena2a
...
/home/linuxbrew/.linuxbrew/Cellar/opena2a/0.10.13: 8,316 files, 354.1MB, built in 9 seconds
$ opena2a --version
opena2a 0.10.13
Telemetry: on (opt-out: OPENA2A_TELEMETRY=off  •  details: opena2a.org/telemetry)
```

Use the full `opena2a-org/tap/<formula>` name: it taps this repository and trusts only that formula. After a plain `brew tap`, current Homebrew refuses `brew install opena2a` with `Refusing to load formula ... from untrusted tap`.

Or install individual tools standalone:

```bash
brew install opena2a-org/tap/secretless-ai   # Secret protection only
brew install opena2a-org/tap/hackmyagent     # Security scanning only
brew install opena2a-org/tap/ai-trust        # Trust verification only
```

> **Note:** `opena2a` bundles its own copies of HackMyAgent, Secretless AI and ai-trust for its subcommands, but puts only the `opena2a` command on your PATH. Install the individual formulae for the standalone `hackmyagent`, `secretless-ai` and `ai-trust` commands.

## Formulae

| Formula | Package | Formula file |
|---------|---------|--------------|
| `opena2a` | [opena2a-cli](https://www.npmjs.com/package/opena2a-cli) | [Formula/opena2a.rb](Formula/opena2a.rb) |
| `secretless-ai` | [secretless-ai](https://www.npmjs.com/package/secretless-ai) | [Formula/secretless-ai.rb](Formula/secretless-ai.rb) |
| `hackmyagent` | [hackmyagent](https://www.npmjs.com/package/hackmyagent) | [Formula/hackmyagent.rb](Formula/hackmyagent.rb) |
| `ai-trust` | [ai-trust](https://www.npmjs.com/package/ai-trust) | [Formula/ai-trust.rb](Formula/ai-trust.rb) |

Each formula file names the npm release it installs.

---

### opena2a

**One CLI for all OpenA2A security tools.** Scan, protect, benchmark, and monitor AI agents from a single command. Detect Shadow AI -- unmanaged agents and MCP servers running in your environment. Bundles HackMyAgent, Secretless AI, and ai-trust as integrated subcommands.

```bash
brew install opena2a-org/tap/opena2a

opena2a init                    # Assess project security posture (read-only)
opena2a protect                 # Migrate credentials to an encrypted vault
opena2a guard                   # Sign and verify config file integrity
opena2a scan-soul               # Behavioral governance (OASB-2)
opena2a check <package>         # Is this package safe to install?
opena2a secrets                 # Manage secrets (via Secretless AI)
opena2a detect                  # Discover AI agents running on this machine
```

Full documentation: [github.com/opena2a-org/opena2a](https://github.com/opena2a-org/opena2a)

---

### secretless-ai

**AI coding tools can read your secrets. Secretless makes them invisible.** Prevents API keys, tokens, and credentials from leaking into AI coding tool contexts. Works with Claude Code, Cursor, GitHub Copilot, Windsurf, Cline, and Aider.

```bash
brew install opena2a-org/tap/secretless-ai

secretless-ai init              # Set up protection for your project
secretless-ai secret set KEY    # Store a secret
secretless-ai run -- node app   # Run with secrets injected as env vars
secretless-ai verify            # Confirm secrets are hidden from AI
secretless-ai protect-mcp       # Protect MCP server credential configs
secretless-ai doctor            # Diagnose shell profile issues
```

Full documentation: [github.com/opena2a-org/secretless-ai](https://github.com/opena2a-org/secretless-ai)

---

### hackmyagent

**Find what can go wrong before an attacker does.** Security scanner for MCP servers, A2A agents, LangChain tools, and other AI agent frameworks, with auto-fix and rollback. `hackmyagent --help` prints its current check and payload counts ([formula notes](docs/formulae.md#hackmyagent)).

```bash
brew install opena2a-org/tap/hackmyagent

hackmyagent secure              # Full security scan
hackmyagent secure --deep       # Static, semantic and behavioral analysis
hackmyagent scan-soul           # 72 behavioral governance controls (OASB-2)
hackmyagent harden-soul         # Generate hardened config from results
hackmyagent trust <package>     # Check package trust before installing
hackmyagent secure --category credentials,injection,permissions
```

Full documentation: [github.com/opena2a-org/hackmyagent](https://github.com/opena2a-org/hackmyagent)

---

### ai-trust

**Check the trust score of any AI package before you install it.** Queries the OpenA2A trust graph for security scans, community consensus, dependency risk, and known advisories.

```bash
brew install opena2a-org/tap/ai-trust

ai-trust check server-filesystem  # MCP shorthand (resolves to @modelcontextprotocol/server-filesystem)
ai-trust audit package.json       # Audit all dependencies
ai-trust batch server-fetch express  # Batch lookup (MCP names auto-resolve)
```

Full documentation: [github.com/opena2a-org/ai-trust](https://github.com/opena2a-org/ai-trust)

---

## How They Work Together

This workflow uses the standalone `secretless-ai` and `hackmyagent` commands, which the Quick Start does not put on your PATH. Install their formulae first:

```bash
brew install opena2a-org/tap/secretless-ai
brew install opena2a-org/tap/hackmyagent
```

Then run:

```bash
secretless-ai init              # 1. Protect secrets from AI tools
opena2a init                    # 2. Set up security configuration
hackmyagent secure --deep       # 3. Scan for vulnerabilities
opena2a scan-soul               # 4. Verify behavioral governance
```

**Secretless** keeps credentials safe during development. **HackMyAgent** finds security issues in your agents. **OpenA2A** orchestrates the full security workflow. `opena2a` bundles all three for its own subcommands; the standalone `secretless-ai` and `hackmyagent` commands come from their own formulae.

## Upgrade

```bash
brew upgrade                    # Upgrade every outdated formula, these included
brew upgrade opena2a            # Or upgrade one formula you installed
```

Name only formulae you installed: `brew upgrade` stops with `Refusing to load formula ... from untrusted tap` on a formula from this tap that you have not installed by its tap-qualified name.

## Alternative Installation

```bash
npm install -g opena2a-cli      # One CLI; bundles HMA, Secretless, ai-trust
npm install -g secretless-ai    # Standalone
npm install -g hackmyagent      # Standalone
npm install -g ai-trust         # Standalone
```

As with the formula, `opena2a-cli` puts only the `opena2a` command on your PATH; its bundled copies of HackMyAgent, Secretless AI and ai-trust are set by `opena2a-cli` and can be older than the standalone packages.

## Documentation

- [docs/formulae.md](docs/formulae.md): formula notes the README links instead of repeating
- [docs/captures/quick-start.md](docs/captures/quick-start.md): where and when the Quick Start capture was taken
- [STATUS.md](STATUS.md): maintenance status of this tap

## License

Apache-2.0
