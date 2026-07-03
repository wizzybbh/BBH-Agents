# XSS — Cross-Site Scripting

Still ubiquitous. Modern apps auto-escape, so the wins are in **DOM XSS**,
framework escape-hatches, and injection into non-HTML contexts. Read + reason
only — prove with a benign marker, never a real payload against users.

## Types & where they live

- **Reflected** — input echoed in the immediate response (search, error, params).
- **Stored** — persisted then rendered (comments, profile, filenames, support
  tickets, admin-viewed logs → **blind XSS**).
- **DOM** — client-side sink executes source without a server round-trip. The big
  modern surface: SPA frameworks + `location`/`postMessage`/`innerHTML`.

## Framework escape-hatches (fingerprint → sink)

- **React** — `dangerouslySetInnerHTML`, `href={userInput}` (`javascript:`),
  `ref` + `innerHTML`, `eval`/`Function`, unsanitized `<a target>` `rel`.
- **Vue** — `v-html`, dynamic `:href`, `v-bind` of a `javascript:` URL, template
  compilation of user input.
- **Angular** — `bypassSecurityTrust*`, template injection (client-side, `{{}}`),
  `[innerHTML]`, old Angular CSTI.
- **Server templating** — un-escaped output (`{!! !!}` Blade, `| safe` Jinja,
  `<%- %>` EJS, `.html()`/`v-html`) — many of these are also SSTI (see ssti.md).

## Context-aware payloads

Identify the context, break out precisely:
- **HTML body**: `<img src=x onerror=alert(document.domain)>`,
  `<svg onload=alert(document.domain)>`.
- **Attribute**: `"><svg onload=...>` or event-handler break `" onmouseover=alert()// `.
- **JS string**: `';alert(document.domain)//`, `</script><svg onload=...>`.
- **URL/href**: `javascript:alert(document.domain)`.
- **DOM sink**: `#<img src=x onerror=alert()>` via `location.hash`,
  `?param=` into `innerHTML`; `postMessage` handlers without origin check.
- **Polyglot** (fast triage):
  `jaVasCript:/*-/*`/*\`/*'/*"/**/(/* */oNcliCk=alert() )//%0D%0A%0d%0a//</stYle/</titLe/</teXtarEa/</scRipt/--!>\x3csVg/<sVg/oNloAd=alert()//>`

## WAF / filter bypasses (current)

- Case/whitespace: `<sVg OnLoAd=…>`, tabs/newlines in tags/attrs.
- Encodings: HTML entities, URL double-encoding, unicode (`alert`), `String.fromCharCode`.
- No parens: `onerror=alert;throw document.domain`, template-literal call `alert\`1\``.
- Alt events/tags when `script`/`onerror` filtered: `onpointerover`, `onfocus autofocus`, `<details open ontoggle=…>`.
- Mutation XSS (mXSS) via innerHTML re-parsing; DOMPurify bypasses (check version — several `< 3.x` bypasses).
- CSP: look for `unsafe-inline`, `unsafe-eval`, wildcard/JSONP/`strict-dynamic`
  gadgets, allowlisted CDN with a callable script; nonce reuse.

## Escalation / impact (for CVSS)

Session/token theft (if not HttpOnly), account takeover via CSRF-on-behalf,
credential-harvest UI overlay, admin-panel stored/blind XSS (highest value),
worm potential. Same-origin sensitive-action = high.

## Blind XSS

Inject into fields an employee/admin later views (support tickets, user-agent,
signup name, referrer). Use **XSS Hunter-style** OOB payload with a callback that
captures DOM/URL/cookies of whoever renders it.

## Tools

Caido/Burp; **DalFox** (param XSS scanner, as leads), **kxss**/`gxss`, `Gf` xss
patterns, **XSS Hunter/interactsh** for blind, DOM Invader (Burp) for DOM sinks.

## Safe PoC

`alert(document.domain)` or a DOM marker / OOB callback proving execution in the
target origin. Do **not** deploy cookie-stealers against real users.

## References (current)

- PortSwigger Web Security Academy — XSS & DOM XSS; DOM Invader.
- OWASP XSS Filter Evasion / HTML sanitization notes.
