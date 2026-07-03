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

## Consequences

- "Caido integration" means **read + suggest**, not auto-replay. Reached via a
  community/self-built reader over Caido's plugin/GraphQL API (no first-party
  MCP).
- Active *recon* tooling (subfinder/httpx/gau) is a separate category: `/recon`
  may run it in **automated mode** only after the operator explicitly chooses
  that mode. Attack traffic at a target is never automated.
- If this is ever revisited (guarded auto-replay), it must be per-skill,
  scope-enforced, rate-limited, and supersede this ADR.
