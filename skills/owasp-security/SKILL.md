---
name: owasp-security
description: Security code review using OWASP Top 10:2025 standards. Use when reviewing auth code, payment logic, user input handling, or when someone says "security review", "check for vulnerabilities", "OWASP check", or "is this code secure?".
---

# OWASP Security Review

Perform a security review of the code or PR described below using OWASP Top 10:2025 standards.

Target: $ARGUMENTS

---

## Quick Reference: OWASP Top 10:2025

| # | Vulnerability | Key Prevention |
|---|---------------|----------------|
| A01 | Broken Access Control | Deny by default, enforce server-side, verify ownership |
| A02 | Security Misconfiguration | Harden configs, disable defaults, minimize features |
| A03 | Supply Chain Failures | Lock versions, verify integrity, audit dependencies |
| A04 | Cryptographic Failures | TLS 1.2+, AES-256-GCM, Argon2/bcrypt for passwords |
| A05 | Injection | Parameterized queries, input validation, safe APIs |
| A06 | Insecure Design | Threat model, rate limit, design security controls |
| A07 | Auth Failures | MFA, check breached passwords, secure sessions |
| A08 | Integrity Failures | Sign packages, SRI for CDN, safe serialization |
| A09 | Logging Failures | Log security events, structured format, alerting |
| A10 | Exception Handling | Fail-closed, hide internals, log with context |

## Security Code Review Checklist

### Input Handling
- [ ] All user input validated server-side
- [ ] Using parameterized queries (not string concatenation)
- [ ] Input length limits enforced
- [ ] Allowlist validation preferred over denylist

### Authentication & Sessions
- [ ] Passwords hashed with Argon2/bcrypt (not MD5/SHA1)
- [ ] Session tokens have sufficient entropy (128+ bits)
- [ ] Sessions invalidated on logout
- [ ] MFA available for sensitive operations

### Access Control
- [ ] Authorization checked on every request
- [ ] Using object references user cannot manipulate
- [ ] Deny by default policy
- [ ] Privilege escalation paths reviewed

### Data Protection
- [ ] Sensitive data encrypted at rest
- [ ] TLS for all data in transit
- [ ] No sensitive data in URLs/logs
- [ ] Secrets in environment/vault (not code)

### Error Handling
- [ ] No stack traces exposed to users
- [ ] Fail-closed on errors (deny, not allow)
- [ ] All exceptions logged with context
- [ ] Consistent error responses (no enumeration)

---

## Review Process

1. Read the target code/PR
2. Run through each checklist section above
3. For each finding: cite the specific line, the OWASP category, and the fix
4. Prioritize: Critical (exploitable now) > High (likely exploitable) > Medium > Low
5. Provide a summary with total findings by severity

For secure code patterns (Go, JavaScript/TypeScript), see `references/secure-code-patterns.md`.
For agentic AI security and ASVS 5.0 requirements, see `references/agentic-ai-security.md`.

## Error Handling

| Situation | Action |
|-----------|--------|
| Code language not covered in patterns | Apply OWASP principles generically; note the gap |
| Minified/bundled code | Flag as unreviewable; request source |
| No auth code found | Confirm auth is handled elsewhere; don't assume secure |
| Third-party library vulnerability | Check CVE databases; note version and known issues |
| Insufficient context | List assumptions made; request clarification |
