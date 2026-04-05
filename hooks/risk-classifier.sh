#!/bin/bash
# risk-classifier.sh — Unified PreToolUse hook with 3-tier risk classification
#
# Classifies every Bash command into HIGH/MEDIUM/LOW risk tiers.
#   HIGH   → block (exit 2) + audit log
#   MEDIUM → warn (stderr) + audit log
#   LOW    → audit log only
#
# Replaces: block-keychain.sh + exfiltration-detector.sh

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

AUDIT_LOG="$HOME/.claude/state/hook-audit.jsonl"
mkdir -p "$(dirname "$AUDIT_LOG")" 2>/dev/null

# Truncate command for audit log (no full commands in logs for safety)
CMD_PREFIX=$(echo "$COMMAND" | head -c 100 | tr '\n' ' ')

# Strip quoted strings to avoid false positives
STRIPPED=$(echo "$COMMAND" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g")

# ─── Audit helper ────────────────────────────────────────────────
audit() {
  local tier="$1" action="$2" pattern="$3"
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"tier\":\"$tier\",\"action\":\"$action\",\"pattern\":\"$pattern\",\"command_prefix\":\"$(echo "$CMD_PREFIX" | sed 's/"/\\"/g')\"}" >> "$AUDIT_LOG" 2>/dev/null
}

# ─── HIGH tier: block + log ──────────────────────────────────────
# H1: macOS keychain access
if echo "$STRIPPED" | grep -qiE '(^|\s|;|&&|\||\$\()(/usr/bin/)?security(\s|$)'; then
  echo "BLOCKED: macOS security/keychain commands are prohibited" >&2
  audit "HIGH" "blocked" "keychain"
  exit 2
fi

# H2: Pipe to network tools (exfiltration)
if echo "$STRIPPED" | grep -qiE '\|[[:space:]]*(ssh|nc|ncat|netcat)\b'; then
  echo "BLOCKED: Pipe to network tool detected (exfiltration risk)" >&2
  audit "HIGH" "blocked" "pipe_to_network"
  exit 2
fi

# H3: Bash TCP/UDP redirect
if echo "$STRIPPED" | grep -qE '>\s*/dev/(tcp|udp)/'; then
  echo "BLOCKED: Bash network redirect detected (exfiltration risk)" >&2
  audit "HIGH" "blocked" "tcp_udp_redirect"
  exit 2
fi

# H4: Netcat listener or reverse shell
if echo "$STRIPPED" | grep -qiE '\bnc\s+-[le]|\bncat\s+-[le]'; then
  echo "BLOCKED: Netcat listener/exec detected (exfiltration risk)" >&2
  audit "HIGH" "blocked" "netcat_listener"
  exit 2
fi

# H5: Encoded data piped to curl/wget
if echo "$STRIPPED" | grep -qiE '(base64|xxd|od)\s.*\|.*(curl|wget)'; then
  echo "BLOCKED: Encoded data transfer detected (exfiltration risk)" >&2
  audit "HIGH" "blocked" "encoded_exfil"
  exit 2
fi

# ─── MEDIUM tier: warn + log ────────────────────────────────────
# M1: Reading sensitive credential files
if echo "$STRIPPED" | grep -qiE '(cat|head|tail|less|more|bat)\s+.*(\/etc\/shadow|\.ssh\/id_|\.aws\/credentials|\.gnupg\/|\.netrc)'; then
  echo "WARNING: Reading sensitive file detected (risk: credential exposure)" >&2
  audit "MEDIUM" "warned" "sensitive_file_read"
  exit 0
fi

# M2: curl/wget with POST to non-allowlisted domains
if echo "$STRIPPED" | grep -qiE '(curl|wget)\s.*(-X\s*POST|--data|--data-raw|-d\s)' && \
   ! echo "$STRIPPED" | grep -qiE '(localhost|127\.0\.0\.1|api\.github\.com|hooks\.slack\.com)'; then
  echo "WARNING: POST request to external domain detected" >&2
  audit "MEDIUM" "warned" "external_post"
  exit 0
fi

# M3: Dangerous permissions
if echo "$STRIPPED" | grep -qE 'chmod\s+(777|a\+rwx)\s'; then
  echo "WARNING: World-writable permission detected" >&2
  audit "MEDIUM" "warned" "chmod_777"
  exit 0
fi

# M4: Recursive delete outside /tmp
if echo "$STRIPPED" | grep -qE 'rm\s+-[rR]f?\s' && ! echo "$STRIPPED" | grep -qE 'rm\s+-[rR]f?\s+(/tmp/|/var/tmp/)'; then
  echo "WARNING: Recursive delete outside /tmp detected" >&2
  audit "MEDIUM" "warned" "recursive_delete"
  exit 0
fi

# ─── LOW tier: log only ─────────────────────────────────────────
audit "LOW" "allowed" "none"
exit 0
