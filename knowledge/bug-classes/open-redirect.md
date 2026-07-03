# Open Redirect

Low severity alone, but a **force multiplier**: chains into OAuth token theft,
SSRF filter bypass, and phishing. Cheap to test across all recon URLs. Read + reason.

## Where it lives

Params: `redirect, redirect_uri, redirect_url, url, next, return, returnUrl,
return_to, dest, destination, continue, goto, out, target, to, r, u, link,
callback, forward, path, image_url, ref`. Login/logout flows, SSO/OAuth, "back to"
links, email link trackers, post-action redirects.

## Payloads / bypasses

```
?next=https://evil.com
?next=//evil.com                 (protocol-relative)
?next=https:evil.com             (missing slashes)
?next=/\evil.com   ?next=\/\/evil.com   ?next=/%2F/evil.com
?next=https://target.com.evil.com          (suffix)
?next=https://evil.com?target.com          (?/# gadget)
?next=https://evil.com#target.com
?next=https://evil.com@target.com  reversed → @evil.com
?next=%68ttp%3a%2f%2fevil.com    (encoding)  double-encode
?next=javascript:alert(1)        (→ XSS if used in href/location)
?next=data:text/html,...         whitelist-bypass via allowed-domain open redirect gadget
CRLF: ?next=%0d%0aLocation:https://evil.com  (→ header injection/response splitting)
```
Try appending the allowed host (`target.com.evil.com`, `evil.com/target.com`) and
`@`, `#`, `?`, backslash, and encoding tricks against naive "contains target.com" checks.

## High-value chains (why it matters)

- **OAuth/SSO token theft** — open redirect on an allowed `redirect_uri` leaks the
  `code`/`access_token` in the URL/fragment to attacker → account takeover. This
  turns a "low" into a **critical**.
- **SSRF allowlist bypass** — server follows redirect from an allowed host to an
  internal target (see ssrf.md).
- **CSP/whitelist bypass**, credential phishing on trusted domain, cookie/`Referer` leak.

## Method

Confirm the redirect actually navigates (3xx `Location:` or client-side
`location=`) to your external host. Then look for the chain (is this the OAuth
`redirect_uri`? does an internal fetcher follow it?).

## Safe PoC

Redirect to a benign host you control (your OAST/`example.com`). For OAuth chains,
show the `code`/token landing on your `redirect_uri` — using **your own** account.

## Tools

`gf redirect` + `qsreplace 'https://oast.host'` over recon URLs, **OpenRedireX**,
Caido/Burp; kxss-style reflection check.

## References (current)

- PortSwigger — DOM-based open redirection & OAuth `redirect_uri` labs.
- PayloadsAllTheThings — Open Redirect.
