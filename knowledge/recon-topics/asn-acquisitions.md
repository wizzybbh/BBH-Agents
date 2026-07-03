# Scope Expansion — ASNs, Acquisitions, Reverse-WHOIS

Do this **before** subdomain enumeration. The biggest recon edge is finding roots
others miss — acquired companies, owned IP ranges, sister brands. Only act on what
the program's scope authorizes (wildcards/roots you're allowed to test).

## Acquisitions & brands

- **Crunchbase / Wikipedia / SEC filings (10-K)** → subsidiaries & acquisitions.
- Company "brands"/"our family" pages, press releases ("X acquires Y").
- Map each acquired brand to its apex domains → candidate new roots.
- **Confirm scope**: many programs list "and all acquisitions" or exclude recent
  ones (grace period). Check policy; when unsure, ask/skip.

## ASN → IP ranges → domains

- Find the org's **ASN**: `whois -h whois.radb.net -- '-i origin AS<N>'`,
  **bgp.he.net**, **asnmap** (`asnmap -d target.com`), **amass intel -org "Target"`.
- ASN → CIDR ranges → reverse-DNS / probe: `mapcidr` + `dnsx -ptr`, `httpx` the
  ranges to find apps on owned IPs (careful: cloud IPs are shared — an ASN owned
  by AWS is NOT the target; only self-hosted ranges count).
- `amass intel -asn <N>` to pull domains seen on the ASN.

## Reverse-WHOIS & registrant pivots

- **whoxy / viewdns reverse-whois** by org name, registrant email → other domains
  the org registered. `amass intel -whois -d target.com`.
- Pivot on unique registrant email/phone/org string.

## Favicon / analytics / fingerprint pivots

- **Favicon hash**: compute mmh3 hash of `/favicon.ico`, search Shodan
  `http.favicon.hash:<h>` / FOFA → other hosts sharing the same favicon (same org).
- **Google Analytics / GTM / Ad IDs**: `UA-`/`G-`/`GTM-` and AdSense `pub-` IDs
  are reused across an org's properties → **builtwith**, **publicwww**,
  **spyonweb**, **analyzeid** to find sibling domains.
- **TLS cert** SANs / cert-transparency org fields; **Shodan** `ssl.cert.subject.CN`, `org:"Target"`.

## Output

A vetted list of **apex domains / wildcard roots** in scope → feed each to
subdomain-enum. Record which are confirmed in-scope vs "found but out-of-scope"
(drop the latter). Update the program's `scope.txt` if new roots are authorized.

## Tools

amass intel, asnmap, mapcidr, bgp.he.net, whoxy/viewdns reverse-whois, shodan
(favicon/org), builtwith/publicwww (analytics IDs), crt.sh, SEC EDGAR.

## Guardrail

Scope expansion **finds** surface; it does not authorize it. Test only what the
program's scope covers. When a discovered asset's scope is ambiguous, treat as
out-of-scope until confirmed.
