# Agentic AI Security (OWASP 2026)

When reviewing AI agent systems or Claude Code integrations:

| Risk  | Description                    | Mitigation                                |
| ----- | ------------------------------ | ----------------------------------------- |
| ASI01 | Goal Hijack (prompt injection) | Input sanitization, goal boundaries       |
| ASI02 | Tool Misuse                    | Least privilege, validate I/O             |
| ASI03 | Privilege Abuse                | Short-lived scoped tokens                 |
| ASI04 | Supply Chain (plugins/MCP)     | Verify signatures, sandbox, allowlist     |
| ASI05 | Code Execution                 | Sandbox execution, human approval         |
| ASI06 | Memory Poisoning (RAG)         | Validate stored content, segment by trust |
| ASI07 | Agent Comms Spoofing           | Authenticate, encrypt, verify integrity   |
| ASI08 | Cascading Failures             | Circuit breakers, graceful degradation    |
| ASI09 | Trust Exploitation             | Label AI content, verification steps      |
| ASI10 | Rogue Agents                   | Behavior monitoring, kill switches        |

---

## ASVS 5.0 Key Requirements

| Level | Applies To       | Key Requirements                                                                                  |
| ----- | ---------------- | ------------------------------------------------------------------------------------------------- |
| L1    | All Apps         | Passwords 12+ chars, breached list check, rate limiting, 128-bit session tokens, HTTPS everywhere |
| L2    | Sensitive Data   | All L1 + MFA, key management, security logging, input validation on all params                    |
| L3    | Critical Systems | All L1/L2 + HSM for keys, threat modeling, advanced monitoring, pen testing                       |
