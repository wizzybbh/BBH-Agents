# Permit GET-only sends under mandatory confirmation (amends ADR 0002)

> **Status: REVERTED — never operative in practice.** drift's `send_request` was
> broken (bad mutation schema), and fixing `create_replay_session` (staging)
> delivered the operator's "stage, I click Send" workflow *without any agent
> send*. So `send_request` was removed from the drift allowlist and
> [ADR 0002](0002-human-stays-the-trigger.md) never-send stands. This record is
> kept for history; the decision below is **not in effect**.

We soften [ADR 0002](0002-human-stays-the-trigger.md) at the operator's explicit
request. The agent MAY call the Caido MCP's `send_request` to **replay a
read-only GET request**, but only when gated by the operator's **per-call
confirmation prompt**. It must NOT send any state-changing method
(POST/PUT/PATCH/DELETE) and must NOT call `run_workflow` or any other transmit
tool — those stay operator-fired in Caido Replay.

## Why (and the honest cost)

The operator wanted "reads-on-confirm" to speed iteration. GET replays are
idempotent and non-destructive, and a human still approves every send. The cost,
surfaced by the `/hunt` agent itself: this moves the *decision to queue a send*
into the model, with the human as approver rather than initiator. So the clean
guarantee "the agent never puts bytes on the wire" becomes the weaker "the agent
sends GET-only, and only what the human approves." Writes remain fully manual.

## Enforcement (layered — no single point of trust)

1. **Skill charter** — `/hunt` may `send_request` only for GET; stages everything
   else. This is what stops the agent, above the permission layer.
2. **Tool exposure** — drift's `DRIFT_ALLOWED_TOOLS` exposes `send_request` but
   withholds `run_workflow`, `set_environment`, `intercept_pause`/`resume`.
3. **Confirmation** — `settings.json` `permissions.ask: ["mcp__drift__send_request"]`
   forces a prompt on every send; run the session in a prompting mode (not
   auto/bypass) or the prompt can be skipped.
4. **Method gate is human** — drift does not filter by HTTP method, so the
   operator MUST verify the request is a GET at the confirmation prompt. Decline
   anything that isn't.

## Reverting

If confidence erodes, restore the original ADR 0002 posture: remove
`send_request` from `DRIFT_ALLOWED_TOOLS` (read/stage-only) and drop the `ask`
rule. The agent then sends nothing, and the operator fires all requests by hand.
