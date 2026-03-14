# OpenA2A Homebrew Tap

Homebrew formulae for the [OpenA2A](https://opena2a.org) open-source AI security platform. Three CLI tools that work together to secure AI agent ecosystems.

## Quick Start

```bash
brew tap opena2a-org/tap
brew install opena2a secretless-ai hackmyagent
```

## Available Formulae

### opena2a (v0.5.11)

The unified security CLI for AI agents. Scans packages from the [OpenA2A Registry](https://registry.opena2a.org), verifies trust levels, and hardens agent configurations.

```bash
brew install opena2a

# Scan an AI agent package for security issues
opena2a scan <package-name>

# Initialize security configuration for your project
opena2a init

# Protect MCP server configs, skill files, and agent manifests
opena2a protect

# Run runtime guardrails for agent execution
opena2a guard

# Scan agent soul (behavioral governance) against OASB-2
opena2a scan-soul

# Query the trust registry
opena2a registry query <package>
```

### secretless-ai (v0.12.4)

One command to keep secrets out of AI. Prevents API keys, tokens, and credentials from leaking into AI coding tool contexts. Works with Claude Code, Cursor, GitHub Copilot, Windsurf, and any AI coding assistant.

```bash
brew install secretless-ai

# Set up secret protection for your project
secretless-ai init

# Store a secret (encrypted locally)
secretless-ai secret set ANTHROPIC_API_KEY

# Run a command with secrets injected as env vars
secretless-ai run -- node server.js

# Verify no secrets are exposed in AI transcripts
secretless-ai verify

# Protect MCP server configs from credential exposure
secretless-ai protect-mcp

# Check system health and configuration
secretless-ai doctor
```

### hackmyagent (v0.10.1)

Security scanner purpose-built for AI agents. Finds vulnerabilities in MCP servers, A2A agents, LangChain tools, CrewAI setups, and other AI agent frameworks. Implements [OASB-1](https://oasb.ai/oasb-1) (security) and [OASB-2](https://oasb.ai/oasb-2) (behavioral governance) standards.

```bash
brew install hackmyagent

# Run a full security scan on your project
hackmyagent secure

# Scan with LLM-powered semantic analysis
hackmyagent secure --deep

# Scan agent soul (72 behavioral governance controls)
hackmyagent scan-soul

# Generate hardened configuration from scan results
hackmyagent harden-soul

# Check specific categories
hackmyagent secure --category credentials,injection,permissions
```

## Upgrade

```bash
brew upgrade opena2a secretless-ai hackmyagent
```

## How They Work Together

```
secretless-ai init          # Protect your secrets from AI tools
opena2a init                # Set up registry trust verification
hackmyagent secure --deep   # Scan your agent for vulnerabilities
opena2a scan-soul           # Verify behavioral governance (OASB-2)
```

**Secretless** keeps credentials safe during development. **HackMyAgent** finds security issues in your agents. **OpenA2A** connects to the trust registry and orchestrates the full security workflow.

## Alternative Installation

All tools are also available via npm:

```bash
npm install -g opena2a-cli
npm install -g secretless-ai
npm install -g hackmyagent
```

## Links

- [OpenA2A Platform](https://opena2a.org)
- [OpenA2A Registry](https://registry.opena2a.org)
- [OASB Standards](https://oasb.ai)
- [GitHub Organization](https://github.com/opena2a-org)

## License

Apache-2.0
