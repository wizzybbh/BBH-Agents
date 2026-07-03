# CORS Misconfiguration & CSRF

Two client-trust bugs. CORS misconfig → cross-origin data theft; CSRF → forced
state-changing actions. Read + reason; prove with your own accounts/PoC page.

## CORS misconfiguration

The server reflects/allows an untrusted origin **with credentials** → attacker
site reads authenticated responses.

**Test**: send `Origin: https://evil.com` and inspect response headers:
- `Access-Control-Allow-Origin: https://evil.com` (reflected) **+**
  `Access-Control-Allow-Credentials: true` → **exploitable**, steal authed data.
- `ACAO: *` with credentials is spec-blocked, but `*` on an endpoint returning
  secrets to a *token* (not cookie) can still leak.
- **Origin-reflection bypasses**: `null` origin (`ACAO: null` — sandbox iframe /
  `data:` doc sends `Origin: null`), suffix/prefix trust
  (`eviltarget.com`, `target.com.evil.com`), regex holes (`target.com` matched
  anywhere), pre-`.` subdomain trust (`evil.target.com` if any subdomain trusted →
  chain with XSS/takeover on a subdomain), non-`https` schemes.

**Impact**: read PII/API keys/CSRF-tokens cross-origin → ATO. PoC page fetches the
authed endpoint from `evil.com` and exfils to attacker.

## CSRF

Force a logged-in victim's browser to send a state-changing request.

**Preconditions**: action is cookie-authed, no unpredictable token / no SameSite
protection, request forgeable (predictable body).

**Test**:
- Remove the CSRF token — still accepted? Use another user's token — accepted?
- Empty/malformed token accepted? Token not tied to session?
- Method downgrade `POST`→`GET`; `Content-Type` change to
  `text/plain`/`application/x-www-form-urlencoded` to avoid preflight.
- **SameSite gaps**: `Lax` still allows top-level GET navigations → GET-based CSRF;
  cookies without SameSite on older browsers; `Lax+POST` 2-min window.
- JSON endpoint → try form/`text/plain` re-encoding to dodge CSRF-by-content-type.
- Chain: **open redirect / CORS / XSS** to defeat token or SameSite.

**Impact**: email/password change → ATO, fund transfer, privilege change, account deletion.

## Safe PoC

CORS: host a page on your origin that fetches the authed endpoint (your 2nd
account) and displays the response. CSRF: an auto-submitting form/HTML PoC that
performs a benign state change on **your own** account; screenshot the result.

## Tools

Caido/Burp (CORS* checks, CSRF PoC generator), `corsy`, browser devtools,
PortSwigger CORS/CSRF labs.

## References (current)

- PortSwigger Web Security Academy — CORS & CSRF (+ SameSite).
- PayloadsAllTheThings — CORS / CSRF.
