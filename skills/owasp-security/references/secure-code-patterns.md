# Secure Code Patterns

Language-specific examples of secure vs insecure patterns.

## Go — SQL Injection Prevention

```go
// UNSAFE
query := fmt.Sprintf("SELECT * FROM users WHERE id = %s", userID)
db.Raw(query)

// SAFE — parameterized
db.Where("id = ?", userID).Find(&user)

// SAFE — raw with params
db.Raw("SELECT * FROM users WHERE id = ?", userID).Scan(&user)
```

## Go — Command Injection Prevention

```go
// UNSAFE
exec.Command("sh", "-c", "convert " + filename + " output.png")

// SAFE — separate arguments
exec.Command("convert", filename, "output.png")
```

## Go — Race Conditions

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

## Go — Template Injection

```go
// UNSAFE — marks user input as safe HTML
template.HTML(userInput)

// SAFE — auto-escaped by default
{{.UserInput}}
```

## JavaScript/TypeScript — XSS Prevention

```javascript
// UNSAFE — directly sets HTML from user input (XSS risk)
element.innerHTML = userInput

// SAFE — escapes HTML entities automatically
element.textContent = userInput

// SAFE (Vue.js) — auto-escaped by template engine
{{ userInput }}

// UNSAFE (Vue.js) — renders raw HTML without sanitization
// <div v-html="userInput" />
```

## JavaScript/TypeScript — Prototype Pollution

```javascript
// UNSAFE
Object.assign(target, userInput)
_.merge(target, userInput)

// SAFE — null prototype prevents pollution
Object.assign(Object.create(null), validated)
```

## Password Storage

```go
// UNSAFE — SHA256 is not designed for password hashing
hash := sha256.Sum256([]byte(password))

// SAFE — bcrypt with adaptive cost factor
hash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
```

## Fail-Closed Pattern

```go
// UNSAFE — fail-open allows access on error
func checkPermission(user, resource string) bool {
    result, err := authService.Check(user, resource)
    if err != nil {
        return true // DANGEROUS: grants access on error
    }
    return result
}

// SAFE — fail-closed denies access on error
func checkPermission(user, resource string) bool {
    result, err := authService.Check(user, resource)
    if err != nil {
        log.Error("auth check failed", "error", err)
        return false // Deny on error
    }
    return result
}
```
