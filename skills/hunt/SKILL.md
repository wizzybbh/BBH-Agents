---
name: hunt
description: Build a per-bug-class test plan for one target from its profile and its Caido traffic — exact payloads and modified requests the operator fires manually. Use when the user runs /hunt, wants concrete payloads for a target/bug class, or shares Caido traffic to attack. The AI never sends requests.
---

# /hunt — Target + Caido traffic → payloads you fire yourself

The "pentester brain." Given a **Target**, its `/profile`, and its captured
**Caido traffic**, produce concrete, ready-to-fire test cases for the operator to
execute in Caido Replay. **Per ADR 0002, this skill never sends any request** —
it reads and hands you the exact thing to send. Authorized-testing only.

## Inputs

- The target + the bug class(es) to focus on (from `/profile` HUNT PRIORITIES).
  If none given, ask or take the top priority from the profile.
- **Caido traffic** for the target — use the `caido-reader` subagent to pull the
  relevant requests/responses (method, path, params, headers, cookies, body,
  response codes/reflections). Or read a saved request the user provides.
- `~/targets/<prog>/scope.txt` — confirm scope, note rules & `max_severity`,
  required User-Agent.

## Load the deep playbook first

Before planning, pull the full playbook for the focus class from the repo's
**bug-class library** at `~/.claude/bb-knowledge/bug-classes/<class>.md`
(symlinked by `install.sh`; else the repo's `knowledge/bug-classes/`). Each has
current payloads, bypasses, escalation, and safe-PoC guidance.
Map focus → file:
`idor/bola/access` → `access-control-idor.md` · `ssrf` → `ssrf.md` ·
`graphql` → `graphql.md` · `jwt/auth/ato` → `jwt-auth.md` · `xss` → `xss.md` ·
`ssti` → `ssti.md` · `sqli/nosqli` → `sqli-nosqli.md` ·
`lfi/traversal` → `path-traversal-lfi.md` · `xxe` → `xxe.md` ·
`rce/cmdi` → `command-injection.md` · `upload` → `file-upload.md` ·
`proto pollution` → `prototype-pollution.md` · `cache` → `web-cache-poisoning.md` ·
`cors/csrf` → `cors-csrf.md` · `redirect` → `open-redirect.md` ·
`takeover` → `subdomain-takeover.md` · `race/logic` → `race-conditions.md`.
If the library isn't present, fall back to the inline essentials below.

## Method — per bug class

For each class, ground the payloads in a **real captured request** (so they're
valid for this app), state what to change, what a positive result looks like, and
the safe/non-destructive way to prove it. Pull the exact payloads/bypasses from
the loaded playbook — don't rely on memory for current bypasses.

- **IDOR** — find object-id params (numeric/UUID/slug) in captured requests.
  Test: with account A's session, swap the ID to account B's object; also try
  removing/forging tenant headers. Positive: A reads/edits B's data. Need 2 accounts.
- **MFLAC** — find privileged endpoints (admin/config/user-mgmt) in traffic.
  Test: call them with a low-priv session / no session; try forced browsing to
  admin routes; method-swap (GET↔POST). Positive: privileged action succeeds.
- **SSRF** — params that fetch URLs (`url,dest,callback,image,webhook,proxy`).
  Test: point at a collaborator/OAST host you control; try `169.254.169.254`
  metadata, `localhost`, alt schemes/encodings. Positive: OAST hit or internal resp.
- **XSS** — reflected/stored sinks; check the framework's escape (JSX/Blade/Jinja
  autoescape vs `dangerouslySetInnerHTML`/`{!! !!}`/`v-html`). Test contextual
  payloads (HTML/attr/JS/URL). Prove with a benign `alert`-equivalent / DOM marker.
- **SSTI** — template-rendered inputs (name/report/export fields). Test the
  polyglot `${{<%[%'"}}%\` then engine probes (`{{7*7}}`, `${7*7}`, `<%= 7*7 %>`).
  Positive: arithmetic evaluates.
- **SQLi** — params hitting the DB. Test error/boolean/time payloads suited to the
  stack; prefer safe boolean/time proofs over destructive ones.
- **Open redirect** — `redirect,next,return,url` params → external host; check 3xx `Location`.
- **CSRF** — state-changing POSTs; check for token presence/validation, SameSite.

## Output

```
### HUNT: <host>  |  class: <focus>  |  <prog>  |  max-sev: <>  |  <today>

## SETUP
UA: <required user-agent>   accounts needed: <1 / 2 (A,B)>   OAST: <your collaborator host>

## TEST CASES  (fire in Caido Replay — do NOT let the AI send)
1. <class> @ <METHOD path>
   base (captured): <the real request line + key headers/params>
   change: <exact param/header/body edit + payload>
   positive result: <what proves it>
   safe-proof: <non-destructive confirmation>
<repeat, ordered by likelihood × severity>

## NOTES
- <framework default that may block this + the misuse that beats it>
- <rate/WAF caution; keep within program automation rules>

## ▶ IF CONFIRMED → /report <host> <class>
```

## Guardrails

- **NEVER send a request.** Output is copy-paste-into-Caido material. This is the
  core promise of the suite (ADR 0002).
- **Scope + severity + rules** — in-scope only; respect `max_severity`, required
  UA, rate posture; no brute-force/DoS where excluded.
- **Non-destructive proofs** — boolean/time/OAST over data-changing payloads;
  never exfiltrate real user PII to prove a point.
- **Grounded payloads** — build from captured requests so they're valid for the app.
- **No fabricated success** — a payload is a lead until the operator sees the positive result.
