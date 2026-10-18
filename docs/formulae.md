# Formula notes

Notes on the formulae in this tap that the [README](../README.md) links instead of repeating. The version each formula installs is the npm release named in its file under [Formula/](../Formula/).

## hackmyagent

The README's hackmyagent section carried this sentence until the counts moved here:

310 static checks, 29 NanoMind semantic checks, 164 adversarial payloads as of 2026-08-25 (hackmyagent 0.32.0), auto-fix with rollback.

On 2026-10-18, `hackmyagent --help` of hackmyagent 0.33.2, the release [Formula/hackmyagent.rb](../Formula/hackmyagent.rb) installs, printed this summary line:

```text
Security scanner for AI agents. 363 checks, 164 attack payloads, auto-fix.
```

Run `hackmyagent --help` for the counts of the version you have installed.

The README's `hackmyagent scan-soul` example carried this comment until the count moved here:

```bash
hackmyagent scan-soul           # 72 behavioral governance controls (OASB-2)
```

In the hackmyagent 0.32.0 package, the `scan-soul` help text gives the number of security controls as the size of the governance control catalog, which defines 72 controls. Run `hackmyagent scan-soul --help` for the count of the version you have installed.
