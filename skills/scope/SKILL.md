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

1. **Pasted POLICY / brief text** — rules of engagement, test plans, reward tiers, CVSS/VRT, exclusions.
2. **The authoritative asset list** — format depends on platform:
   - **HackerOne** — program → Scope → "Export as CSV". Columns:
     `identifier, asset_type, instruction, eligible_for_bounty,
     eligible_for_submission, max_severity, …`.
   - **Bugcrowd** — the brief's **Targets** table (In-Scope + Out-of-Scope
     sections), usually pasted rather than a clean CSV. Each target has a
     **category** (Website / API / Android / iOS / …), an in/out flag, and a
     **VRT priority** ceiling instead of `max_severity`. The "Out of Scope" list
     is authoritative excludes.

Detect the platform from the input and parse accordingly. The CSV/brief may
already be on the VPS — if the user names a path (`~/targets/<prog>/scope.csv`),
read it directly; don't ask them to paste. If only one input exists, use it and
note what's missing. **Asset list = asset truth; policy = rules truth.** Never
invent — missing → "not specified."

## 2. Parse the asset list (authoritative)

Per row / target:
- **In scope** ⇔ H1 `eligible_for_submission = true` (Bugcrowd: under In-Scope
  Targets); **Out** ⇔ false / in the Out-of-Scope list.
- **Paid** ⇔ H1 `eligible_for_bounty = true`. `submission=true` + `bounty=false`
  → **in scope, VDP-only (no money)** — label ⊘.
- Classify by type (H1 `asset_type` / Bugcrowd category):
  - `WILDCARD` / identifier starting `*.` → **RECON TARGET** (subdomain enum authorized).
  - `URL` / Website (single host) → **fixed web host** — test directly; do **NOT** enumerate its parent.
  - `CIDR` / `IP_ADDRESS` → **IP-range recon target** — port/service scan the range (NOT subdomain enum). Watch shared cloud IPs.
  - `API` → API host/base — fixed host; drive API testing (see `bug-classes/graphql.md`, `access-control-idor.md`).
  - `APPLE_STORE_APP_ID` / `GOOGLE_PLAY_APP_ID` / `TESTFLIGHT` / Android / iOS → **mobile app**.
  - `DOWNLOADABLE_EXECUTABLES` / `WINDOWS_APP_STORE_APP_ID` → **desktop app**.
  - `SOURCE_CODE` → repo in scope — GitHub recon / code review (see `recon-topics/github-dorking.md`).
  - `HARDWARE` / AI model / `OTHER` → misc — read `instruction`/brief.
- Ceiling: H1 `max_severity` or Bugcrowd **VRT priority** (P1–P5) per target.

**State loudly:** only **wildcard** assets authorize subdomain enumeration. A
specific in-scope URL (`photoshop.adobe.com`) does NOT make `*.adobe.com` in
scope. If only apex/URL hosts are listed (no wildcard), RECON TARGETS = "none" —
do not enumerate a parent you weren't given.

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

### IP / CIDR RANGES (port/service recon; NOT subdomain enum)
<1.2.3.0/24 ...   or "none">

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

### REWARD TIERS  (H1: severity/CVSS · Bugcrowd: VRT P1–P5)
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
- Keep the source `scope.csv` / brief alongside at `~/targets/<slug>/` for re-parsing.
- **Format contract (the chain depends on it):** the RECON TARGETS block MUST list
  wildcard roots as `*.domain` lines (space- or newline-separated).
  `recon-pipeline.sh -p <slug>` and `/recon` parse *exactly* that block — anything
  not matching `*.domain` there is ignored, and fixed hosts must stay OUT of it.
  Get this right and `/scope → /recon` is one clean handoff.
- `/recon` and `/triage` read this file to enforce scope.

## 6. Guardrails

- **CSV = asset truth, policy = rules truth.** Disagreement → trust CSV for in/out, FLAG in NOTES.
- **Never fabricate.** Missing → "not specified."
- **Conservative by default** on automation/rate when unstated; never brute-force.
- **Point-in-time snapshot** — re-export before a fresh engagement; live program is truth.
- Keep it ~one screen.
