---
name: triage
description: Turn raw recon output (httpx live-host lists, gau/katana URL dumps) into a ranked, actionable target shortlist — hot→cold, with why each host matters and what to test first. Use when the user runs /triage, points at httpx/live_detailed output on the VPS, or pastes a big list of URLs/hosts to prioritize.
---

# /triage — Recon output → ranked hunting shortlist

Take a pile of recon output and turn it into a prioritized operating doc: which
hosts/URLs to hunt first, WHY, and WHAT to test. The AI's job is to **read and
prioritize** — never to send requests. Authorized-testing context only.

## 1. Inputs

Read files directly on the VPS when the user names a path (e.g.
`~/targets/<prog>/recon/live_detailed.txt`) — don't make them paste. Otherwise
accept pasted input. One or both of:
1. **httpx output** — `https://host [status] [title] [tech,tech]`.
2. **A URL/endpoint dump** — gau / katana / waybackurls (can be thousands of lines).

If `~/targets/<prog>/scope.txt` exists, read it and **enforce scope**: drop
anything not under an in-scope wildcard/host; honor rules (stage-only, OOS,
3rd-party filter). Never rank an out-of-scope asset. For giant URL dumps, hand
off to the `url-miner` subagent and triage its clusters.

## 2. Signals — what makes a host/URL "hot" (stack signals, not any one)

**Environment & naming (high):** `dev- stage- staging- test- qa- uat- internal- admin- debug- old- beta- preprod-` → forgotten/weaker surface.

**Status code:** `401/403` → gated (access-control bugs) — *distinguish app-auth 403 from edge/CDN/IP block* ("Access Denied", Akamai/CloudFront deny) → may need a registered testing IP. `200` on odd host → dig. `500/400` → misconfig/needs input. `404` on root ≠ dead — app lives in paths.

**Title:** Admin, Dashboard, Login, Staging, Internal, API, Debug, Swagger, phpMyAdmin, Jenkins, GraphQL → lean in.

**Tech fingerprint → bug-class** (fast version; full table in
`knowledge/framework-bugclass-matrix.md`, deep per-class playbooks in
`knowledge/bug-classes/`):
- **AEM** → `/system/console`, `/crx/de`, `/etc.json`, dispatcher bypass, default creds.
- **WOPI** → doc API: IDOR on file IDs, SSRF via source params, token validation.
- **S3 / CloudFront** → bucket misconfig, subdomain takeover, path traversal.
- **GraphQL / Swagger / OpenAPI** → introspection, exposed endpoints.
- **Old frameworks / known CVEs** → version-specific (with PoC only).
- **Jenkins / GitLab / Grafana / Kibana / phpMyAdmin** → exposed-panel / default-cred / known-vuln.
- **React/Vue/Angular SPA** → the bug is in the **API behind it** — mine the JS bundle for endpoints.

**URL/param signals (for dumps):**
- Injectable params: `?url= ?redirect= ?next= ?file= ?path= ?id= ?dest= ?callback= ?template= ?domain=` → SSRF / open-redirect / LFI / IDOR.
- Sensitive paths: `/admin /api /graphql /actuator /debug /.git /backup /swagger /internal /_next /wp-admin`.
- Extensions: `.json .xml .bak .old .zip .sql .log .env .config`.

## 3. Output — fill this template

```
### TRIAGE: <program> — <N hosts / N URLs in>   |  <today>

## 🔴 HOT — hunt first
- <host/url> [<status>] [<tech>]
    why: <stacked signals in one line>
    test: <2-4 concrete first moves / bug classes>
<top 3-5>

## 🟠 WARM — after the hot ones
- <host/url> — why: <...>  test: <...>

## ⚪ COLD — low priority / park
- <host/url> — <one-line reason>

## ⚠️ FLAGS
- <IP-block vs app-auth 403; testing-IP registration; scope caveats; anything odd>

## ▶ NEXT ACTIONS
1. <e.g. /profile the #1 hot host>
2. <e.g. content-discover hot hosts with ffuf>
3. <e.g. url-miner the top host, re-triage the URLs>
```

For big URL dumps, cluster (by host → interesting path/param pattern) and surface
only notable clusters + counts — don't list every line.

## 4. Guardrails

- **Read & prioritize only — never send requests or run tools.**
- **Enforce scope** if scope.txt exists; never promote OOS/3rd-party.
- **Root status codes lie** — 403/404 on `/` still needs content discovery.
- **No fabricated findings** — "interesting to check" ≠ "vulnerable." Leads to verify.
- **Honor program rules** (throttle, required UA, no brute-force where excluded).
- ~One screen. It's a shortlist, not a report. Hand hot hosts to `/profile`.
