# Race Conditions & Business Logic

Timing/logic flaws that bypass limits you "shouldn't" be able to. High value on
financial and quota features; often missed by scanners. Read + reason only; test
against your own account/balance.

## Race conditions (TOCTOU)

The gap between check and use lets parallel requests each pass the same check.

**Where**: coupon/gift-card/promo redemption, withdrawal/transfer, "one per user"
actions, vote/like, invite acceptance, 2FA/OTP verification, account creation,
rate limits, stock/inventory, points/loyalty, referral bonuses.

**How to test**:
- **Single-packet attack** (HTTP/2) — send N requests so they arrive in the same
  window; Turbo Intruder `race-single-packet-attack` / Burp Repeater "send group
  in parallel". This is the modern, reliable method (Kettle's research).
- HTTP/1.1: last-byte sync (Turbo Intruder `gate`).
- Look for: balance going negative, coupon applied twice, limit exceeded, duplicate
  resource, 2 accounts with same unique value.

**Sub-types**: limit-overrun (spend once, credited twice), multi-endpoint (parallel
calls to different endpoints sharing state), single-endpoint double-submit,
partial-construction (use an object mid-creation).

## Business logic flaws (test the intent, not the input)

- **Price/quantity tampering** — negative qty, `price=0`, currency swap, decimal
  (`0.001`), integer overflow, apply discount after total.
- **Workflow bypass** — skip a step (go straight to `/checkout/confirm`), reorder
  steps, replay a completed step, force-browse to post-payment state.
- **Parameter-driven privilege** — `role`, `plan`, `isTrial`, `verified` in
  requests; feature flags in responses.
- **Quota/limit logic** — reset via re-registration, negative decrement, refund
  loops, coupon stacking.
- **Insufficient validation on state transitions** — cancel-after-ship, refund
  more than paid, approve your own request.
- **Auth logic** — password reset for another user, email-change without
  re-verify, "remember me" never expiring.

## Method

Model the feature's *intended* rules, then find the input/timing that breaks the
invariant. Business logic needs understanding, not payloads — read the app (use
`/profile`).

## Safe PoC

Prove on **your own** account/balance: two coupon redemptions, negative balance,
one extra credit. Screenshot the parallel requests + the invariant broken. Don't
drain real funds or abuse at scale.

## Tools

**Turbo Intruder** (single-packet attack), Burp Repeater parallel send, Caido
match-and-replace + parallel; careful manual reasoning for logic.

## References (current)

- PortSwigger Research — *Smashing the state machine* (single-packet attack) & race-condition labs.
- PortSwigger Web Security Academy — Business logic vulnerabilities.
