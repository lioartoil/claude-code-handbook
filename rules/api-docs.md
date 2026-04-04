# API Documentation Rule

Before writing code against any third-party API, SDK, or external service:

1. **Check `chub` first** — run `chub search "<library>"` to see if curated docs exist
2. **If found** — fetch with `chub get <id> --lang <py|js|ts>` and use those docs
3. **If not found** — fall back to Context7 MCP (`resolve-library-id` → `query-docs`)
4. **After task** — annotate any discoveries (`chub annotate <id> "note"`) and rate the doc (`chub feedback <id> up|down`)

Never rely on training knowledge for API shapes when current docs are available.
