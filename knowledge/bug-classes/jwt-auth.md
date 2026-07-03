# JWT & Authentication Attacks

JWTs gate auth on most modern APIs; flaws → account takeover / auth bypass. Six
critical JWT CVEs landed in 2025 (alg confusion, verify-skip, key recovery).
Read + reason only.

## Decode & inspect first

Base64url-decode header + payload (Caido/jwt.io offline). Note `alg`, `kid`,
`jku`/`jwk`/`x5u` header params, and claims: `sub`, `role`/`scope`, `iss`, `aud`,
`exp`, `iat`, `tenant`. Look for over-trusted claims (`isAdmin`, `email`, `uid`).

## Attack checklist

1. **`alg:none`** — set header `{"alg":"none"}`, strip the signature (keep the
   trailing dot). Try `none`, `None`, `NONE`, `nOnE`. If accepted → forge any claim.
2. **Algorithm confusion (RS256→HS256)** — server verifies asymmetric tokens but
   can be tricked into HMAC. Take the **public key** (from `/jwks.json`,
   `/.well-known/jwks.json`, TLS cert, or docs), sign a forged token with HS256
   using that public key as the HMAC secret. If it validates → ATO. (CVE-2025-4692
   class.) PortSwigger's JWT extension / `jwt_tool` automate this.
3. **Signature not verified** — change the payload, keep/garble the signature; if
   still accepted, verification is skipped (CVE-2025-30144 class).
4. **`kid` injection** —
   - Path traversal: `"kid":"../../../../dev/null"` → empty key → sign with empty secret.
   - Point `kid` at a predictable file whose contents you know (`/proc/sys/...`,
     a static asset) → forge using that as the key.
   - **`kid` SQLi**: `"kid":"x' UNION SELECT 'attacker-secret'-- -"` → server pulls
     your secret from the query result.
5. **`jku`/`x5u` injection** — set header `jku` to an attacker-hosted JWKS with
   your public key; sign with your private key. Works if the server fetches the
   URL without allowlisting host (chain with SSRF/open-redirect on an allowed host).
6. **`jwk` header injection** — embed your own public key in the token header;
   some libs trust it directly.
7. **Weak HMAC secret** — brute HS256 with `hashcat -m 16500` / `jwt_tool`
   wordlist (`jwt.secrets`, rockyou). Weak secret → forge anything.
8. **Claim tampering** — after any bypass: escalate `role`, swap `sub`/`uid`
   (→ IDOR-via-JWT), extend `exp`, change `tenant`/`aud`.
9. **Expiry/replay** — is `exp` enforced? Are old/leaked tokens still valid? Is
   there logout/rotation? Reuse across tenants?

## Non-JWT auth issues to sweep alongside

Password reset token predictability/leak (host-header poisoning of reset link),
OTP/2FA brute (+ GraphQL/HTTP batching), session fixation, OAuth `redirect_uri`
open-redirect / `state` missing (CSRF), pre-account-takeover, response-manipulation
2FA bypass (`{"success":false}`→`true`), and username enumeration on login/reset.

## Tools

**jwt_tool** (all-in-one: none/confusion/kid/jku, cracking), PortSwigger **JWT
Editor** Burp ext, **hashcat -m 16500**, jwt.io (offline), interactsh for jku SSRF.

## Safe PoC

Forge a token elevating **your own** account (or read your own second account) —
demonstrate signature/claim control without touching third-party accounts.

## References (current)

- PortSwigger Web Security Academy — JWT attacks & algorithm confusion.
- 2025 JWT CVEs: CVE-2025-4692 (alg confusion), CVE-2025-30144 (verify bypass),
  CVE-2025-27371 (ECDSA key recovery).

> Sources: [PortSwigger JWT](https://portswigger.net/web-security/jwt), [Algorithm confusion](https://portswigger.net/web-security/jwt/algorithm-confusion), [JSMon alg-confusion/jku/kid-SQLi](https://blogs.jsmon.sh/jwt-algorithm-confusion-to-account-takeover-rs256-hs256-jku-injection-kid-sqli/), [Red Sentry JWT 2026](https://redsentry.com/resources/blog/jwt-vulnerabilities-list-2026-security-risks-mitigation-guide)
