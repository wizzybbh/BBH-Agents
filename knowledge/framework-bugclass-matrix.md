# Framework → Bug-Class Matrix

Where bugs tend to live per stack. Fingerprint the target's framework first
(headers, cookies, error pages, JS bundles, main-file names below), then bias
testing toward that framework's **high-risk** classes. Risk = likelihood the
class is *exploitable on that stack by default*, not a guarantee. Always verify.

Legend: **High** = common, test first · **Mod** = plausible, worth probing ·
**Low** = default protections usually hold, needs a misuse · **N/A** = not a
concern at that layer (usually a server-side vs client-side split).

## Client-side frameworks (bugs are mostly server-behind + DOM)

| Framework | Config / secrets | Main file | Notable classes |
|---|---|---|---|
| **React** | `.env` at project root (CRA) | `index.js`, `App.js` | XSS **Low** (JSX auto-escapes; risk = `dangerouslySetInnerHTML`, or `ref` + `innerHTML` with user input). Server-side classes N/A on the SPA — test the API behind it. |
| **jQuery** | none (library) | n/a | XSS **Mod** — selectors/sinks (`.html()`, `$(userinput)`) inadvertently execute. DOM-based bugs. |
| **Angular** | `environments/` dir | `main.ts` | XSS **Low** (built-in sanitizer; risk = `bypassSecurityTrust*`). CSRF **Low** (built-in token support). Client-side templating → avoid `[innerHTML]` misuse. |
| **Vue.js** | `.env` at project root (Vue CLI) | `main.js` | XSS **Low** (auto-escape; risk = `v-html`). Everything else is on the backend. |

**Client-SPA rule:** the SPA rarely holds the bug — enumerate and test the
**API/backend** it calls. Use the SPA's JS bundle to find endpoints, params,
and hidden routes.

## Server-side runtimes / frameworks (the real attack surface)

| Framework | Config / secrets | Main file | Top classes to test |
|---|---|---|---|
| **Node.js** | `.env` root; `config/` | `index.js`, `server.js` | **LFI High** (direct fs access w/o sanitizing input) · **SSTI High** (dynamic template render) · **IDOR High** (manual checks needed) · **MFLAC High** (explicit access-control required) · SQLi/ParamPollution/SSRF **Mod** |
| **Express.js** | `.env`; `config/` or in `app.js` | `app.js`, `index.js` | **SSTI High** · **IDOR High** · **MFLAC High** (must be hand-coded) · CSRF/SQLi/SSRF/LFI/ParamPollution **Mod** (needs `csurf`, ORMs, input validation) |
| **ASP.NET Core** | `appsettings.json` at root | `Startup.cs` | Mostly **Mod / Low** — strong defaults (output encoding, EF parameterized queries, anti-CSRF tokens, identity/access-control framework). Probe LFI/SSTI/CSRF/SQLi/ParamPollution/SSRF/IDOR/MFLAC at **Mod**. |
| **Django** | `settings.py` in main app | `urls.py`, `views.py` | **Low/Mod** — auto-escaping templates, ORM, CSRF middleware, permissions system. Risk spots: raw HTML in templates, `.raw()`/`extra()` querysets, SSRF via URL fetches, IDOR if perms misconfigured. |
| **Flask** | `config.py` or in `app.py`; `.env` | `app.py` | **IDOR High** · **MFLAC High** (no built-in access control — must be explicit) · SSTI/LFI/CSRF/SQLi/SSRF/ParamPollution **Mod** (Jinja2 autoescapes, but Flask ships little else — CSRF needs Flask-WTF). |
| **Next.js** | `.env`, `next.config.js` | `pages/`, `_app.js`, API routes | **Low/Mod** — inherits React XSS protections; SSR needs care. IDOR/MFLAC **Mod** — enforce checks in API routes & server functions. SSRF **Mod** via API routes. |
| **Laravel** | `.env` root; `config/` dir | `web.php`, `api.php` | **Low/Mod** — Blade auto-escapes (risk = `{!! !!}`), Eloquent parameterizes, CSRF middleware by default. IDOR/MFLAC/SSRF/LFI **Mod** — policies/gates must be defined explicitly; validate raw input & external URLs. |

## More stacks (added beyond the original TBHM tables)

| Stack | Fingerprint | Config / paths | Top classes & known hot spots |
|---|---|---|---|
| **WordPress** | `wp-content`, `wp-json`, `X-Pingback`, `/wp-login.php` | `wp-config.php`; `/wp-json/` | **Plugin/theme CVEs are the #1 win** (enumerate versions → known exploit). User enum `/?author=1`, `wp-json/wp/v2/users`. XML-RPC brute/DoS. Arbitrary upload via vulnerable plugins. `wp-config.php` disclosure. Tools: **wpscan**. |
| **Spring / Spring Boot** (Java) | `X-Application-Context`, whitelabel error, `/actuator` | `application.properties/.yml` | **Actuator exposure** (`/actuator/env`, `/heapdump` → secrets, `/mappings`, `/gateway`). **SpEL injection** → RCE. Spring4Shell class. Path-traversal via `..;/`. IDOR/MFLAC in `@RestController`. |
| **Ruby on Rails** | `X-Runtime`, `_session_id`, CSRF meta, `/rails/info` | `config/`, `credentials.yml.enc` | Mass-assignment (**strong params** gaps) → priv-esc. Deserialization/`Marshal` RCE. `render`/path traversal, `send_file` LFI. Old secret_key_base → cookie forgery. `/rails/info/routes` leak. |
| **Django** (server-rendered) | `csrfmiddlewaretoken`, `X-Frame`, admin at `/admin/` | `settings.py` | See main table + **`DEBUG=True`** settings/secret dump, `/admin` brute, `SECRET_KEY` → session forgery, SSRF in URL fetchers, `.raw()`/`extra()` SQLi. |
| **API-first / headless (REST/GraphQL/gRPC)** | JSON everywhere, `/api/v*`, `Bearer` tokens | OpenAPI/`swagger.json` | **BOLA/IDOR & BFLA dominate** (API1/API5:2023). Mass-assignment (API3). Broken auth/JWT (API2). Excessive data exposure. Enumerate with the spec; test every object id across two accounts. See `bug-classes/access-control-idor.md`, `graphql.md`, `jwt-auth.md`. |
| **Next.js** (server) | `x-powered-by: Next.js`, `/_next/` | `next.config.js`, `.env` | See main table + **SSRF CVE-2024-34351 / CVE-2025-57822** (Host/resolve mismatch), middleware-auth bypass CVE-2025-29927 (`x-middleware-subrequest`), `/_next/image` SSRF, source maps in `/_next/static`. |

## Bug-class glossary (column meanings)

- **XSS** — cross-site scripting (DOM/reflected/stored).
- **LFI** — local file inclusion / path traversal via file ops.
- **SSTI** — server-side template injection.
- **CSRF** — cross-site request forgery.
- **SQLi** — SQL injection.
- **Parameter Pollution** — HTTP parameter pollution (dup/array params).
- **SSRF** — server-side request forgery (URL fetch abuse).
- **IDOR** — insecure direct object reference (swap an ID, get another's data).
- **MFLAC** — Missing Function-Level Access Control (call a privileged
  function/route without authorization).

## How the skills use this

- `/profile` — fingerprint stack → pull that row → list the High/Mod classes as
  the target's hunt priorities, plus config-file/main-file recon hints.
- `/hunt` — for the chosen bug class, cross-reference the framework's default
  protection and the *specific misuse* that defeats it (the "risk =" notes).
- `/triage` — the tech-fingerprint → bug-class hints already inline in that
  skill are the fast version of this table.

> Source: formalized from the operator's TBHM framework/vuln-class reference
> tables. Defaults change with framework versions — treat as a prior, verify live.
