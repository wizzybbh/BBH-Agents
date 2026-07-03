# SSRF — Server-Side Request Forgery

High-impact: pivots to cloud credential theft (AWS/GCP/Azure metadata) and
internal services (Redis, Memcached, admin panels, k8s API). Read + reason only —
hand the operator payloads + a collaborator/OAST host to fire.

## Where it lives (find the URL sinks)

Any feature where the server fetches a URL you influence:
- Params: `url, uri, dest, redirect, callback, image, img, src, source, target,
  proxy, fetch, feed, host, port, to, out, view, domain, webhook, avatar, file, path`.
- Features: webhooks, URL preview/unfurl, PDF/HTML→image converters, image/file
  import-by-URL, SSO/OIDC `redirect_uri`/`jwks_uri`, XML/SVG parsers (→ also XXE),
  "import from URL", link expanders, headless-browser renderers, RSS readers.

## Detection

1. Point the param at a **collaborator/OAST host** you control → DNS/HTTP hit =
   SSRF (even blind). Use per-test unique subdomains to attribute.
2. Compare responses for `http://127.0.0.1`, `http://localhost`, internal RFC1918
   ranges, and known internal hostnames.
3. Blind → look for timing differences, error deltas, or out-of-band callbacks.

## Cloud metadata (the money shot)

- **AWS IMDSv1**: `http://169.254.169.254/latest/meta-data/iam/security-credentials/<role>`
  → steal keys. `.../latest/dynamic/instance-identity/document` for account/region.
- **AWS IMDSv2 (token-gated)**: needs `PUT /latest/api/token` with
  `X-aws-ec2-metadata-token-ttl-seconds` then the token header. Only exploitable
  when the SSRF primitive lets you **control method + headers** (full-request SSRF,
  some proxies). If you can only issue plain GETs, IMDSv2 usually blocks you.
- **GCP**: `http://metadata.google.internal/computeMetadata/v1/` with header
  `Metadata-Flavor: Google` (again needs header control).
- **Azure**: `http://169.254.169.254/metadata/instance?api-version=2021-02-01`
  with `Metadata: true`.
- Alt metadata IP encodings below help past naive blocklists.

## Filter / SSRF-protection bypasses (current)

- **IP encodings**: `2130706433` (decimal), `0x7f000001` (hex), `0177.0.0.1`
  (octal), `127.1`, `0.0.0.0`, `[::1]`, `[::ffff:127.0.0.1]`, `127.0.0.1.nip.io`.
- **DNS rebinding**: a hostname you control that resolves public on first lookup,
  internal on second (TOCTOU) — `rebind`/`taze` services.
- **Parser confusion (2024–25)**: validator and HTTP client parse the URL
  differently. `http://expected.com@169.254.169.254/`,
  `http://169.254.169.254#expected.com`, `http://169.254.169.254\expected.com`,
  backslashes, `://` doubling, unicode dots (`。`), CR/LF, wrapped credentials.
- **Redirect gadget**: allowed host that 3xx-redirects to the internal target
  (open-redirect → SSRF chain); many clients follow redirects to 169.254.
- **Scheme abuse**: `file://`, `gopher://` (craft raw TCP → Redis/SMTP),
  `dict://`, `ftp://`, `ldap://` where the client library supports them.
- **Framework CVEs to fingerprint**: Next.js SSRF via Host-header/resolve-route
  mismatch (CVE-2024-34351, CVE-2025-57822); HTML→PDF `<iframe>` fetch
  (CVE-2025-51591). If the stack matches, test the known vector.

## Internal-service pivots

`gopher://` to Redis (`FLUSHALL`/`SET`… — non-destructive PoC only), internal
admin panels, `http://<internal>:port/`, k8s API `:6443`/`:10250`, Elasticsearch
`:9200`, Docker socket. **In bug bounty: prove access, do not exploit destructively.**

## Safe PoC

OAST callback with a unique token, or read a *non-sensitive* internal endpoint /
metadata *path listing* (not full credential dumps unless the program wants it and
Safe Harbor covers it). Demonstrate reach; don't loot.

## Tools

Burp Collaborator / **interactsh** (OAST), `interactsh-client`; **SSRFmap**,
**Gopherus** (gopher payloads); Caido replay; nuclei ssrf templates (as leads only).

## References (current)

- PortSwigger Web Security Academy — SSRF.
- HackingTheCloud — EC2 metadata SSRF.
- Vulnsy SSRF cheat sheet (2026); appsecure "SSRF in Cloud Environments".

> Sources: [Cyber Samir SSRF filter/metadata bypass](https://cybersamir.com/ssrf-exploitation-bypass-filters-cloud-metadata/), [Vulnsy SSRF 2026](https://www.vulnsy.com/cheat-sheets/ssrf), [HackingTheCloud EC2 metadata SSRF](https://hackingthe.cloud/aws/exploitation/ec2-metadata-ssrf/), [appsecure SSRF in cloud](https://www.appsecure.security/blog/ssrf-cloud-environments)
