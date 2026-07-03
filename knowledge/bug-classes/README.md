# Bug-Class Playbook Library

Deep, current playbooks — one per class. Each follows the same shape: **where it
lives → how to find → current payloads/bypasses → escalation/impact → safe PoC →
tools → references**. `/hunt` and `/profile` read the relevant file(s) for a
target; the operator fires everything ([ADR 0002](../../docs/adr/0002-human-stays-the-trigger.md)).

## Index

| File | Class | Why it pays |
|---|---|---|
| [access-control-idor.md](access-control-idor.md) | IDOR / BOLA / BFLA / mass-assignment | **#1 OWASP 2025** — most consistent bounty |
| [ssrf.md](ssrf.md) | SSRF (+ cloud metadata) | Critical: cloud cred theft, internal pivot |
| [graphql.md](graphql.md) | GraphQL (introspection, batching, BOLA) | Weak authz + rate-limit bypass |
| [jwt-auth.md](jwt-auth.md) | JWT & auth (alg confusion, kid/jku, ATO) | Account takeover; 2025 CVEs |
| [xss.md](xss.md) | XSS (reflected/stored/DOM, framework hatches) | Ubiquitous; blind XSS → admin |
| [ssti.md](ssti.md) | Server-side template injection | Often RCE |
| [sqli-nosqli.md](sqli-nosqli.md) | SQL / NoSQL injection | High severity; auth bypass |
| [path-traversal-lfi.md](path-traversal-lfi.md) | Path traversal / LFI / RFI | File read → secrets → RCE |
| [xxe.md](xxe.md) | XML external entity | File read + SSRF |
| [command-injection.md](command-injection.md) | OS command injection | RCE |
| [file-upload.md](file-upload.md) | Malicious upload | RCE / stored XSS / SSRF |
| [prototype-pollution.md](prototype-pollution.md) | Client & server prototype pollution | DOM XSS / RCE / bypass |
| [web-cache-poisoning.md](web-cache-poisoning.md) | Cache poisoning & deception | Mass impact at scale |
| [cors-csrf.md](cors-csrf.md) | CORS misconfig & CSRF | Cross-origin theft / forced actions |
| [open-redirect.md](open-redirect.md) | Open redirect | Chains → OAuth ATO / SSRF |
| [subdomain-takeover.md](subdomain-takeover.md) | Dangling-DNS takeover | Easy win from recon |
| [race-conditions.md](race-conditions.md) | Race conditions & business logic | Financial / quota bypass |
| [secrets-info-disclosure.md](secrets-info-disclosure.md) | Secrets, JS/source leaks, exposed files, cloud storage | Fastest wins; often critical |

## Cross-references

- **Framework → which classes to prioritize**: [../framework-bugclass-matrix.md](../framework-bugclass-matrix.md).
- **SSRF ↔ XXE ↔ open-redirect ↔ cache** chain together — follow the "chain" notes.
- **JWT ↔ access-control** — a forged `sub`/`role` is IDOR-via-token.

## Maintenance

These encode techniques current as of mid-2026. Bypasses and CVEs move fast —
when a class file is edited, keep the "References (current)" links live and note
new framework CVEs in the relevant playbook. This library is the authoring source;
skills bundle the essentials but should read these for full depth when the repo is present.
