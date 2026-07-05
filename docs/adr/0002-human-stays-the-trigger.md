# The AI never fires attack traffic — the human stays the trigger

Across the whole suite, no skill or subagent sends attack traffic at a live
target. The AI reads captured traffic (e.g. from Caido), analyzes it, and hands
the operator exact payloads/requests to fire themselves. Even the "pentester"
skill (`/hunt`) only *plans and suggests*.

## Why (a "pentester" that deliberately never attacks is surprising)

- **Scope safety.** An AI that auto-sends can drift out of scope, hammer a host,
  trip rate limits/WAFs, or trigger DoS-like behavior — any of which can get a
  researcher banned from a program. Keeping the human as the trigger keeps a
  deliberate, scope-checked hand on every request.
- **Signal quality.** Human-fired testing produces intentional, reviewable
  requests instead of a flood of low-value automated noise.
- **Consistency.** This preserves the existing `/scope` and `/triage` guardrail
  ("read & prioritize only — never send requests") rather than reversing it.

## Staging is allowed; sending is not (Caido MCP, e.g. drift)

When a Caido MCP is connected, the agent MAY use its **read** tools
(`search_history`, `get_request`, `get_scope`/`check_scope`) and MAY **stage** a
request into Caido Replay (`create_replay_session`) so the operator can review and
fire it. The agent MUST NOT call any tool that transmits — `send_request`,
`run_workflow`, etc. The operator presses **Send** in Caido.

Enforce at the permission layer, not by prompt alone: **deny
`mcp__drift__send_request`** (and `mcp__drift__run_workflow`). Verify that
`create_replay_session` only stages (does not fire) before allowing it; if it
fires, deny it too and have the agent hand over the request text for manual paste.
Staging ≠ sending, so this preserves — does not weaken — "the human stays the
trigger." See [caido-mcp-setup.md](../caido-mcp-setup.md).

## Consequences

- "Caido integration" means **read + suggest**, not auto-replay. Reached via a
  community/self-built reader over Caido's plugin/GraphQL API (no first-party
  MCP).
- Active *recon* tooling (subfinder/httpx/gau) is a separate category: `/recon`
  may run it in **automated mode** only after the operator explicitly chooses
  that mode. Attack traffic at a target is never automated.
- If this is ever revisited (guarded auto-replay), it must be per-skill,
  scope-enforced, rate-limited, and supersede this ADR.
