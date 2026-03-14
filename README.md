> **[OpenA2A](https://github.com/opena2a-org/opena2a)**: [CLI](https://github.com/opena2a-org/opena2a) · [HackMyAgent](https://github.com/opena2a-org/hackmyagent) · [Secretless AI](https://github.com/opena2a-org/secretless-ai) · [AIM](https://github.com/opena2a-org/agent-identity-management) · [Browser Guard](https://github.com/opena2a-org/AI-BrowserGuard) · [DVAA](https://github.com/opena2a-org/damn-vulnerable-ai-agent) · **Homebrew Tap**

# OpenA2A Homebrew Tap

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Formulae](https://img.shields.io/badge/formulae-3-brightgreen)]()

Install the OpenA2A security tools with Homebrew. Three CLIs that protect AI agent ecosystems -- scan for vulnerabilities, keep secrets out of AI context, and enforce behavioral governance.

[Website](https://opena2a.org) | [CLI Docs](https://opena2a.org/cli) | [OASB Standards](https://oasb.ai) | [GitHub](https://github.com/opena2a-org)

---

## Quick Start

```bash
brew tap opena2a-org/tap
brew install opena2a secretless-ai hackmyagent
```

## Formulae

| Formula | Version | Package |
|---------|---------|---------|
| `opena2a` | 0.5.11 | [opena2a-cli](https://www.npmjs.com/package/opena2a-cli) |
| `secretless-ai` | 0.12.4 | [secretless-ai](https://www.npmjs.com/package/secretless-ai) |
| `hackmyagent` | 0.10.1 | [hackmyagent](https://www.npmjs.com/package/hackmyagent) |

---

### opena2a

**One CLI for all OpenA2A security tools.** Scan, protect, benchmark, and monitor AI agents from a single command. Detect Shadow AI -- unmanaged agents and MCP servers running in your environment.

```bash
brew install opena2a

opena2a init                    # Initialize security config
opena2a protect                 # Protect MCP configs, skills, manifests
opena2a guard                   # Runtime guardrails for agent execution
opena2a scan-soul               # Behavioral governance (OASB-2)
opena2a scan <package>          # Scan a package for vulnerabilities
opena2a shield                  # Detect shadow AI in your environment
```

Full documentation: [opena2a.org/cli](https://opena2a.org/cli)

---

### secretless-ai

**AI coding tools can read your secrets. Secretless makes them invisible.** Prevents API keys, tokens, and credentials from leaking into AI coding tool contexts. Works with Claude Code, Cursor, GitHub Copilot, Windsurf, Cline, and Aider.

```bash
brew install secretless-ai

secretless-ai init              # Set up protection for your project
secretless-ai secret set KEY    # Store a secret (encrypted locally)
secretless-ai run -- node app   # Run with secrets injected as env vars
secretless-ai verify            # Check for exposed secrets in transcripts
secretless-ai protect-mcp       # Protect MCP server credential configs
secretless-ai doctor            # System health check
```

Full documentation: [opena2a.org/secretless](https://opena2a.org/secretless)

---

### hackmyagent

**Find what can go wrong before an attacker does.** Security scanner for MCP servers, A2A agents, LangChain tools, CrewAI setups, and other AI agent frameworks. 147 checks, 55 adversarial payloads, auto-fix with rollback.

```bash
brew install hackmyagent

hackmyagent secure              # Full security scan
hackmyagent secure --deep       # LLM-powered semantic analysis
hackmyagent scan-soul           # 72 behavioral governance controls (OASB-2)
hackmyagent harden-soul         # Generate hardened config from results
hackmyagent secure --category credentials,injection,permissions
```

Full documentation: [hackmyagent.com](https://hackmyagent.com)

---

## How They Work Together

```bash
secretless-ai init              # 1. Protect secrets from AI tools
opena2a init                    # 2. Set up security configuration
hackmyagent secure --deep       # 3. Scan for vulnerabilities
opena2a scan-soul               # 4. Verify behavioral governance
```

**Secretless** keeps credentials safe during development. **HackMyAgent** finds security issues in your agents. **OpenA2A** orchestrates the full security workflow.

## Upgrade

```bash
brew upgrade opena2a secretless-ai hackmyagent
```

## Alternative Installation

```bash
npm install -g opena2a-cli
npm install -g secretless-ai
npm install -g hackmyagent
```

## License

Apache-2.0
