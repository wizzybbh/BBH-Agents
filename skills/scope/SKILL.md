---
name: scope
description: Turn a bug bounty program's policy text + exported scope CSV into a clean, copy-pasteable scope.txt operating doc. Use when the user runs /scope, pastes a program policy, or uploads/points to a HackerOne/Bugcrowd scope CSV export.
---

# /scope — Bug bounty program scope extractor

Turn a program's **policy text** + **scope CSV export** into a one-screen
operating doc saved to `~/targets/<program>/scope.txt` and fed to recon.
Authorized-testing context only.

## 1. Inputs

Live-fetching H1/Bugcrowd does NOT work (login-gated + JS-rendered). Get inputs from:

1. **Pasted POLICY text** — rules of engagement, test plans, reward tiers, CVSS, exclusions.
2. **An exported scope CSV** — authoritative asset list. H1: program → Scope → "Export as CSV". Columns: `identifier, asset_type, instruction, eligible_for_bounty, eligible_for_submission, max_severity, ...`.

The CSV may already be on the VPS — if the user names a path (e.g.
`~/targets/<prog>/scope.csv`), read it directly with the file tools; don't ask
them to paste it. If only one input exists, use it and note what's missing.
**CSV = asset truth; policy = rules truth.** Never invent — missing → "not specified."

## 2. Parse the CSV (authoritative assets)

Per row:
- **In scope** ⇔ `eligible_for_submission = true`; **Out** ⇔ `false`.
- **Paid** ⇔ `eligible_for_bounty = true`. `submission=true` + `bounty=false` → **in scope, VDP-only (no money)** — label it.
- Classify `asset_type`:
  - `WILDCARD` / `identifier` starting `*.` → **RECON TARGET** (subdomain enum authorized).
  - `URL` → **fixed web host** — test directly; do **NOT** enumerate its parent.
  - `APPLE_STORE_APP_ID` / `GOOGLE_PLAY_APP_ID` → mobile app.
  - `DOWNLOADABLE_EXECUTABLES` → desktop app.
  - `OTHER` → misc/product/AI — read `instruction`.
- Use `instruction` for test-plan pointers; `max_severity` for ceiling.

**State loudly:** only **wildcard** assets authorize subdomain enumeration. A
specific in-scope URL (`photoshop.adobe.com`) does NOT make `*.adobe.com` in scope.

## 3. Parse the policy (rules + rewards)

- **Identity:** required **User-Agent** (often the H1 handle); **registration email alias**; any **Testing-IP** submission requirement (Safe Harbor).
- **Rules of engagement:** automation posture (quote it; infer conservatively from DoS/rate/auto-block language if absent), brute-force (usually excluded), DoS prohibitions, prod/stage restrictions, PII handling, reporting rules.
- **Reward tiers:** each tier's assets + payout range; caps/adjustments.
- **Bounty menu:** CVSS/severity table → top-paying classes. Exclusions → "skip" list.
- **Per-asset caveats** (rate-limit bypass OOS, stage-only, temporarily OOS).

## 4. Output — fill this template

```
### TARGET: <program> (<platform>)  — <bounty | VDP>
LAST READ: <today>   |  HANDLE: <h1 user>
REQUIRED USER-AGENT: <string or "none">   |  REG EMAIL: <alias or "none">
TESTING IP REQUIRED AT SUBMISSION: <yes/no>

### RECON TARGETS (wildcards -> enumerate subdomains)
<*.example.com ...   or "none">

### IN SCOPE — fixed web hosts (test directly, NO parent enum)   [⊘=no bounty]
<host (TIER/ENV) ...>

### IN SCOPE — mobile / desktop / AI / other            [⊘=no bounty]
mobile: <...>   desktop: <... (⊘ unless noted)>   AI: <...>

### OUT OF SCOPE
<assets (submission=false) ...>
3rd-party filter (drop from recon): <domains ...>

### RULES OF ENGAGEMENT
automation: <posture>  | brute-force: <y/n> | DoS: <prohibited? auto-block?>
envs: <prod/stage/local rules> | PII: <rule> | reporting: <one/report, PoC, UA>

### REWARD TIERS
T1: <assets> -> <range>   T2: <assets> -> <range>   T3: <assets> -> <range>
adjustments/caps: <...>

### BOUNTY MENU (prioritize)
top payers: <bug classes + CVSS>
skip (excluded): <list>

### NOTES / AMBIGUITIES
<wildcard-only-enum reminder; CSV vs policy discrepancies; stage-only; gaps>
```

## 5. Save it

- Print the filled template in a code block.
- Write it to `~/targets/<slug>/scope.txt` on the VPS (create the dir). Slug = program handle.
- `/recon` and `/triage` read this file to enforce scope.

## 6. Guardrails

- **CSV = asset truth, policy = rules truth.** Disagreement → trust CSV for in/out, FLAG in NOTES.
- **Never fabricate.** Missing → "not specified."
- **Conservative by default** on automation/rate when unstated; never brute-force.
- **Point-in-time snapshot** — re-export before a fresh engagement; live program is truth.
- Keep it ~one screen.
