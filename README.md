# OpenA2A Homebrew Tap

Homebrew formulae for the [OpenA2A](https://opena2a.org) security platform.

## Installation

```bash
brew tap opena2a-org/tap
brew install opena2a
brew install secretless-ai
brew install hackmyagent
```

## Upgrade

```bash
brew upgrade opena2a secretless-ai hackmyagent
```

## Available Formulae

| Formula | Version | Description |
|---------|---------|-------------|
| `opena2a` | 0.5.11 | Security platform CLI for AI agents - scan, verify, and protect |
| `secretless-ai` | 0.12.4 | Keep secrets out of AI coding tools - works with Claude Code, Cursor, Copilot |
| `hackmyagent` | 0.10.1 | Security scanner for AI agents - find vulnerabilities before attackers do |

## Usage

```bash
# OpenA2A CLI
opena2a --help
opena2a scan <package>
opena2a protect

# Secretless AI
secretless-ai init
secretless-ai verify
secretless-ai run -- <command>

# HackMyAgent
hackmyagent secure
hackmyagent scan-soul
```

## Alternative Installation

```bash
npm install -g opena2a-cli
npm install -g secretless-ai
npm install -g hackmyagent
```

## License

Apache-2.0
