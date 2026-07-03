---
name: report
description: Turn a confirmed finding into a clean HackerOne/Bugcrowd submission — title, CVSS, clear repro steps, impact, and remediation. Use when the user runs /report, has a confirmed vuln to write up, or asks to draft a bug bounty report. Only for findings the user has already verified.
---

# /report — Confirmed finding → submission-ready report

Write a tight, triager-friendly report for a vuln the operator has **already
confirmed**. Good reports get paid faster; padded or speculative ones get closed.
Authorized-testing only.

## Before writing — confirm it's real

Ask for / read: the exact request(s) & response(s) proving it, the bug class,
affected host/endpoint, account context, and the observed impact. If the user
hasn't actually reproduced it, stop — send them back to `/hunt`; do not write a
report for an unverified lead. Read supporting files (saved requests, screenshots)
from the VPS by path.

Pull program specifics from `~/targets/<prog>/scope.txt`: platform (H1/Bugcrowd),
`max_severity` ceiling, required User-Agent, reporting rules (one bug per report,
PoC requirements), reward tier for the asset.

## CVSS (compute a defensible vector)

Build a CVSS 3.1 vector from the **confirmed** impact and show it. Metrics:

- **AV** Attack Vector: `N`etwork (remote/web = default) · `A`djacent · `L`ocal · `P`hysical
- **AC** Attack Complexity: `L`ow (repeatable) · `H`igh (race/special conditions)
- **PR** Privileges Required: `N`one · `L`ow (normal user) · `H`igh (admin)
- **UI** User Interaction: `N`one · `R`equired (victim must click/visit)
- **S** Scope: `U`nchanged · `C`hanged (breaks out of the vulnerable component — SSRF into cloud, XSS across trust boundary)
- **C/I/A** Confid/Integrity/Avail impact: `N`one · `L`ow · `H`igh

Class quick-starts (adjust to the real case — don't just paste):
- **IDOR/BOLA read PII** → `AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N` ≈ 6.5 High; write → `I:H` ≈ 8.1.
- **Account takeover** (auth bypass / JWT forge) → `PR:N/UI:N/C:H/I:H/A:N` ≈ 9.1 Critical.
- **SSRF → cloud metadata** → `PR:L/S:C/C:H` (Scope:Changed) ≈ 9.x.
- **Reflected XSS** → `PR:N/UI:R/S:C/C:L/I:L` ≈ 6.1 Medium; stored/admin → higher.
- **SSTI/RCE** → `C:H/I:H/A:H` ≈ 9.8–10.0.
- **Open redirect** (alone) → `UI:R/C:L` ≈ 4–6; **but** if it chains to OAuth ATO, score the chain.
- **CSRF state change** → `UI:R/I:H` ≈ 6–8 by action.

**Cap** at the asset's `max_severity` if the program sets one, and say you capped.
**Don't inflate** — triagers re-score, and inflation hurts your accuracy stat.
Score the *demonstrated* impact, not the theoretical ceiling (note the ceiling in Impact).

## Repro steps

Numbered, copy-pasteable, minimal. Start from a clean state ("as a standard
user"), include the exact request (method/URL/headers/body) and the exact
observed response that proves it. A triager should reproduce in under 2 minutes
with no guessing. Redact unrelated PII.

## Output — fill this template

```
### TITLE
<Class> on <host><path> allows <impact> — e.g. "IDOR on /api/v2/invoices/{id} exposes other users' invoices"

### PROGRAM
<program> (<platform>)   asset: <in-scope asset>   tier/max-sev: <from scope>

### SEVERITY
CVSS 3.1: <score> (<Critical/High/Med/Low>)   vector: <CVSS:3.1/AV.../...>
CWE: <CWE-nnn>   |   platform priority: <H1 severity / Bugcrowd VRT Pn>
<note if capped to program max-severity>

### SUMMARY
<2-3 sentences: what the bug is and why it matters, in plain language>

### STEPS TO REPRODUCE
1. <clean starting state / account>
2. <exact request — method, URL, headers, body>
3. <exact response / observed behavior>
4. <what confirms the vuln>

### PROOF OF CONCEPT
<the confirming request/response block; screenshot/video refs; OAST hit id>

### IMPACT
<concrete: whose data, what action, blast radius — tie to CVSS>

### REMEDIATION
<specific fix for this class on this stack — e.g. "enforce object-level authz:
verify the session user owns {id} before returning">

### NOTES
<required User-Agent used; testing IP if the program requires it; scope refs>
```

## Platform specifics

**HackerOne** — severity from CVSS 3.1 (None/Low/Med/High/Critical). Report in
Markdown. Include the required **User-Agent** you tested with and, if the program
mandates it, the **testing IP** at submission. One clear vuln per report. Weakness
type = the CWE (state it, e.g. CWE-639 for IDOR, CWE-79 XSS, CWE-918 SSRF).

**Bugcrowd** — priority uses the **VRT** (P1 Critical → P5 Informational), which
maps from the bug class, not just CVSS. Cite the VRT category (e.g. "Broken Access
Control > IDOR > … → P2"). Bugcrowd may still ask for CVSS — provide both. Check
the program brief for VRT adjustments.

Pick the section format the platform expects; the template below is Markdown that
pastes cleanly into either. Map class → CWE and (Bugcrowd) → VRT in NOTES.

## Guardrails

- **Only confirmed findings.** No "might be vulnerable" reports — that burns
  program goodwill and your signal/accuracy.
- **One bug per report** unless the program says otherwise.
- **Honest severity** — score the real impact, respect `max_severity`.
- **Minimal, exact repro** — the #1 thing that gets a report accepted fast.
- **Redact** unrelated PII; include only what proves the bug.
- **Follow program reporting rules** from scope.txt (PoC, UA, testing-IP).
