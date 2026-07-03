---
name: profile
description: Deep app-analysis on ONE chosen host — fingerprint the tech stack, map it to its high-risk bug classes, and produce a content-discovery + auth-model plan. Use when the user runs /profile, picks a host to go deep on, or asks "where do I look on this target." TBHM Day-2 front end.
---

# /profile — One host → app-analysis profile

Given a single chosen **Target** (usually a 🔴 HOT host from `/triage`), build the
"understand the app" artifact that tells you *where the bugs live here*. Read and
reason only — never send attack traffic. Authorized-testing context only.

## Inputs

- The target host/URL.
- Any evidence available: its httpx line (status/title/tech), its JS bundle,
  gau/katana URLs for it, response headers/cookies, a saved page — read files on
  the VPS by path when given. If you have Caido traffic for it, use `caido-reader`.
- `~/targets/<prog>/scope.txt` if present — confirm the target is in scope and
  honor its rules/`max_severity`.

Do not guess the stack from the name — corroborate from headers (`Server`,
`X-Powered-By`, `Set-Cookie` names like `JSESSIONID`/`laravel_session`/`csrftoken`),
error pages, JS framework signatures, and main-file names.

## 1. Fingerprint the stack

Identify: server/runtime, web framework, front-end framework, CDN/WAF, auth
mechanism (session cookie / JWT / OAuth / SSO), APIs (REST/GraphQL/gRPC),
notable third parties. Note the config/main-file hints for that framework.

## 2. Map stack → bug-class priorities (bundled matrix)

Bias hunting toward the framework's high-risk classes. Risk = likelihood the class
is exploitable on that stack by default; always verify.

**Client SPAs (React/Vue/Angular):** the SPA rarely holds the bug — test the
**API behind it**; mine the JS bundle for endpoints/params/hidden routes. XSS is
Low unless `dangerouslySetInnerHTML` / `v-html` / `bypassSecurityTrust*` / `ref`+`innerHTML`.

**Server-side (test-first classes):**
- **Node / Express** → SSTI, IDOR, MFLAC **High**; LFI/SQLi/SSRF/ParamPollution Mod. Access control is hand-coded — probe it hard.
- **Flask** → IDOR, MFLAC **High** (no built-in access control); SSTI/CSRF/SQLi/SSRF Mod (Jinja2 autoescapes; CSRF needs Flask-WTF).
- **Django** → mostly Low/Mod (ORM, CSRF middleware, perms); risk spots: `.raw()`/`extra()`, raw-HTML templates, SSRF via URL fetch, IDOR if perms misconfigured.
- **Laravel** → Low/Mod; risk: `{!! !!}` Blade, undefined policies/gates (IDOR/MFLAC), raw input + external-URL SSRF.
- **ASP.NET Core / Next.js** → strong defaults; probe IDOR/MFLAC/SSRF in API routes & server functions at Mod.

Tech-specific panels seen in fingerprint → their known checks: **AEM**
(`/system/console`, `/crx/de`, dispatcher bypass, default creds), **GraphQL**
(introspection), **Swagger/OpenAPI** (exposed endpoints), **S3/CloudFront**
(bucket misconfig, subdomain takeover), **Jenkins/GitLab/Grafana/Kibana/phpMyAdmin**
(exposed-panel/default-cred/known-CVE with PoC).

(Full table: `~/.claude/bb-knowledge/framework-bugclass-matrix.md`. For each
priority class you surface, the deep playbook lives at
`~/.claude/bb-knowledge/bug-classes/<class>.md` (symlinked by `install.sh`; else
the repo's `knowledge/`). Read the matrix to choose classes; hand the target to
`/hunt`, which loads the class playbook for payloads.)

## 3. Content-discovery & auth plan

- **Content discovery:** tailor a wordlist strategy to the stack (framework
  routes, API paths, `/actuator`, `/_next`, admin panels). Suggest the ffuf/feroxbuster
  command for the user to run — don't run it.
- **Auth model:** how login/session works; roles/tenants (→ IDOR & MFLAC test
  ideas: get two accounts, swap IDs/tokens); registration/password-reset flows.
- **Interesting endpoints:** from JS/urls — params matching SSRF/redirect/LFI/IDOR
  smells; file-upload; export/report generators (SSTI/SSRF); webhooks.

## Output

```
### PROFILE: <host>   |  <prog>   |  <today>   |  max-sev: <from scope>
stack: runtime=<> framework=<> frontend=<> cdn/waf=<> auth=<> api=<>
evidence: <what confirmed each — headers/cookies/bundle/errors>

## HUNT PRIORITIES (stack → classes, highest first)
1. <class> — why here: <framework default/misuse>  — where: <endpoint/feature>
2. ...

## CONTENT DISCOVERY (you run these)
- <ffuf/ferox command + wordlist rationale>

## AUTH MODEL
mechanism: <>  roles/tenants: <>  → access-control tests: <IDOR/MFLAC ideas>

## INTERESTING ENDPOINTS / PARAMS
- <url/param> → <suspected class>

## ⚠ FLAGS  <WAF/IP-block, scope caveats, need 2nd account, testing-IP>
## ▶ NEXT  → /hunt <host> <top class>   (fire payloads yourself in Caido)
```

## Guardrails

- **Read & reason only** — suggest commands/payloads; never send them.
- **Corroborate the stack** — don't fingerprint from the hostname alone.
- **Scope + max-severity aware** — confirm in scope; note the severity ceiling.
- **Priors, not verdicts** — the matrix is a starting bias; verify live.
