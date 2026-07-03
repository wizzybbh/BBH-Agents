# Access Control: IDOR / BOLA / MFLAC

**#1 on the OWASP Top 10 2025 (Broken Access Control); BOLA is API1:2023.** The
most consistent high-value class in bug bounty. If you test one thing well, test
this. Read + reason only — hand the operator the exact swaps to fire.

## The three sub-classes

- **IDOR / BOLA** (object level) — swap an object id and read/write another
  user's data. `GET /api/invoices/1043` → `1044`.
- **BFLA / MFLAC** (function level) — call a privileged *function/route* you
  shouldn't reach. Low-priv user hits `POST /admin/users/{id}/role`.
- **BOPLA / mass-assignment** (property level) — send extra fields the UI never
  exposes: `{"role":"admin"}`, `{"isVerified":true}`, `{"userId":<victim>}`.

## Prerequisites (say this in the plan)

- **Two accounts minimum** (A = attacker, B = victim), ideally at each tier
  (user / moderator / admin) + a fresh unauthenticated context.
- Baseline traffic for both accounts captured in Caido so you have *real* object
  ids and request shapes to swap.

## Where the ids hide (map them all first)

URL path, query string, POST/PUT JSON body, headers (`X-User-Id`, `X-Account`,
`X-Tenant`), cookies, GraphQL node ids, JWT claims (`sub`, `tenant`), multipart
fields, `Referer`, and **nested ids inside batch/GraphQL queries**.

## Test matrix (per identified id)

1. **Horizontal** — A's session, B's id → read? write? delete?
2. **Vertical** — low-priv session → admin function/route.
3. **Unauth** — drop the cookie/token entirely; does it still work?
4. **Method swap** — `GET`→`POST`/`PUT`/`DELETE`/`PATCH`; blocked `POST` may be
   open via `PUT`. Try `X-HTTP-Method-Override: PUT`.
5. **Mass assignment** — add `role/isAdmin/verified/price/status/ownerId` to the body.
6. **ID format tricks** — leading zeros, `1044` vs `"1044"`, array `[1043,1044]`,
   wrapped `{"id":1044}`, UUID vs sequential, base64/hashids-decoded ids.
7. **Path/param pollution** — `?id=1043&id=1044`, `/1043/../1044`, duplicate JSON keys.
8. **Predictability** — sequential? timestamp-based? leaked in another response?

## Bypasses when a check exists

- **Blind IDOR**: no data returned but the action succeeds (state change, email
  sent) → still valid; prove via side effect.
- **Read-only guard**: `GET` denied but `PUT`/`export`/`?format=pdf`/`/download`
  variant leaks the object.
- **UUID ≠ safe**: UUIDs leak in URLs, emails, referers, GraphQL, prior
  responses — harvest, then swap.
- **Second-order**: id accepted in one endpoint, trusted in a later one.
- **GraphQL**: BOLA hides in nested fields and aliased/batched queries — check
  each resolver independently.

## Escalation / impact framing (for CVSS)

PII disclosure, account takeover (reset another's email/password), financial
(change price/quantity/recipient), privilege escalation (mass-assign role),
tenant crossover in multi-tenant SaaS. Write > read for severity.

## Safe PoC

Use your *own* second account (B) as the "victim." Never pull real third-party
PII to prove it — show you can read B's object from A's session. Screenshot both
sessions + the swapped request/response.

## Tools

Caido/Burp Repeater; **Autorize** (Burp) / **AuthMatrix** / Caido's role-compare
workflows for automated two-session diffing; `ffuf`/`arjun` for id & hidden-param
discovery; custom scripts for sequential id sweeps (rate-limited, in scope only).

## References (current)

- OWASP Top 10 2025 — Broken Access Control (A01); API Security Top 10 2023 — BOLA (API1).
- PortSwigger Web Security Academy — Access control & IDOR labs.
- arXiv 2605.25865 — *Broken Object Level Authorization in the Wild* (taxonomy from 100+ disclosures).

> Sources: [IDOR in 2025 (Skrumf)](https://medium.com/@skrumf/idor-in-2025-why-broken-access-control-still-rules-the-vulnerability-charts-with-real-world-d09439eaa29b), [XSSRat IDOR checklist](https://thexssrat.medium.com/the-ultimate-checklist-for-detecting-idor-and-broken-access-control-vulnerabilities-b1585dd4e999), [BOLA in the Wild (arXiv)](https://arxiv.org/pdf/2605.25865)
