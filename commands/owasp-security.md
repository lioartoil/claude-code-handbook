# OWASP Security Review

Perform a security review of the code or PR described below using OWASP Top 10:2025 standards.

Target: $ARGUMENTS

---

## Quick Reference: OWASP Top 10:2025

| #   | Vulnerability             | Key Prevention                                         |
| --- | ------------------------- | ------------------------------------------------------ |
| A01 | Broken Access Control     | Deny by default, enforce server-side, verify ownership |
| A02 | Security Misconfiguration | Harden configs, disable defaults, minimize features    |
| A03 | Supply Chain Failures     | Lock versions, verify integrity, audit dependencies    |
| A04 | Cryptographic Failures    | TLS 1.2+, AES-256-GCM, Argon2/bcrypt for passwords     |
| A05 | Injection                 | Parameterized queries, input validation, safe APIs     |
| A06 | Insecure Design           | Threat model, rate limit, design security controls     |
| A07 | Auth Failures             | MFA, check breached passwords, secure sessions         |
| A08 | Integrity Failures        | Sign packages, SRI for CDN, safe serialization         |
| A09 | Logging Failures          | Log security events, structured format, alerting       |
| A10 | Exception Handling        | Fail-closed, hide internals, log with context          |

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

## Secure Code Patterns

### Go — SQL Injection Prevention

```go
// UNSAFE
query := fmt.Sprintf("SELECT * FROM users WHERE id = %s", userID)
db.Raw(query)

// SAFE — parameterized
db.Where("id = ?", userID).Find(&user)

// SAFE — raw with params
db.Raw("SELECT * FROM users WHERE id = ?", userID).Scan(&user)
```

### Go — Command Injection Prevention

```go
// UNSAFE
exec.Command("sh", "-c", "convert " + filename + " output.png")

// SAFE — separate arguments
exec.Command("convert", filename, "output.png")
```

### Go — Race Conditions

```go
// UNSAFE
go func() { counter++ }()

// SAFE — atomic
atomic.AddInt64(&counter, 1)

// SAFE — mutex
mu.Lock()
counter++
mu.Unlock()
```

### Go — Template Injection

```go
// UNSAFE — marks user input as safe HTML
template.HTML(userInput)

// SAFE — auto-escaped by default
{{.UserInput}}
```

### JavaScript/TypeScript — XSS Prevention

```javascript
// UNSAFE
element.innerHTML = userInput;

// SAFE
element.textContent = userInput;

// SAFE (Vue.js) — auto-escaped
{
  {
    userInput;
  }
}

// UNSAFE (Vue.js) — raw HTML
<div v-html='userInput' />;
```

### JavaScript/TypeScript — Prototype Pollution

```javascript
// UNSAFE
Object.assign(target, userInput);
_.merge(target, userInput);

// SAFE — null prototype
Object.assign(Object.create(null), validated);
```

### Password Storage

```go
// UNSAFE
hash := sha256.Sum256([]byte(password))

// SAFE — bcrypt
hash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
```

### Fail-Closed Pattern

```go
// UNSAFE — fail-open
func checkPermission(user, resource string) bool {
    result, err := authService.Check(user, resource)
    if err != nil {
        return true // DANGEROUS!
    }
    return result
}

// SAFE — fail-closed
func checkPermission(user, resource string) bool {
    result, err := authService.Check(user, resource)
    if err != nil {
        log.Error("auth check failed", "error", err)
        return false // Deny on error
    }
    return result
}
```

---

## Agentic AI Security (OWASP 2026)

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

---

## Review Process

1. Read the target code/PR
2. Run through each checklist section above
3. For each finding: cite the specific line, the OWASP category, and the fix
4. Prioritize: Critical (exploitable now) > High (likely exploitable) > Medium > Low
5. Provide a summary with total findings by severity
