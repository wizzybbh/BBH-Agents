# Caido MCP setup — "agent stages, you send"

Optional. Wires a Caido MCP into Claude Code so the agent can **read** your
captured traffic and **stage** ready-to-fire requests into Caido Replay — while
**you** press Send. Preserves [ADR 0002](adr/0002-human-stays-the-trigger.md):
the agent never transmits attack traffic.

Runs on the **laptop** (where Caido is), for `/profile` and `/hunt`.

## Recommended: drift (six2dez)

Local-first, **no API token** (uses your active Caido session), 18 tools.

```bash
# Prebuilt (easiest): download drift.zip from
#   https://github.com/six2dez/drift/releases
# Or build:
git clone https://github.com/six2dez/drift ~/tools/drift && cd ~/tools/drift
corepack enable && pnpm install && pnpm build      # → dist/drift.zip

# In Caido:  Plugins → Install from file → drift.zip
# In Caido:  drift Settings → Start MCP server (auto-registers with Claude Code)
# Restart Claude Code; it now sees the drift tools.
```

## The guardrail (required) — deny the send tools

The agent must be able to read/stage but **not** fire. Enforce it at the
permission layer, not by trusting the prompt. In the laptop's Claude Code
`settings.json`:

```jsonc
{
  "permissions": {
    "deny": [
      "mcp__drift__send_request",     // fires HTTP via Replay — human only
      "mcp__drift__run_workflow"       // can transmit — human only
    ]
  }
}
```

**Verify `create_replay_session` before trusting it:** have the agent stage one
benign, in-scope request and watch Caido. If it only creates a Replay tab → allow
it (that's the staging you want). If it actually sends → also deny
`mcp__drift__create_replay_session`, and the agent falls back to handing you the
request text to paste into Replay yourself.

## Tool posture

| Allow (read/stage) | Deny (transmit — human only) |
|---|---|
| `search_history`, `get_request` | `send_request` |
| `get_scope`, `check_scope` | `run_workflow` |
| `create_finding`, `list_findings` | `create_replay_session` *(until verified stage-only)* |
| `list_projects`, `select_project`, `get_current_context` | `set_environment`, `intercept_pause`/`intercept_resume` |

## Workflow with staging on

`/hunt` builds each cookie-swapped test case, stages it via
`create_replay_session` into a Caido Replay tab, and tells you which tab to fire.
You review the request, press **Send**, and read the response. Same discipline as
before (one at a time, un-shared object for IDOR, halt on 3rd-party PII) — just
without the manual copy-paste setup.
