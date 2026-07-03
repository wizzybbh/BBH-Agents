# Subdomain Takeover

A dangling DNS record (CNAME/A/NS) points to a deprovisioned third-party service
you can re-claim → serve content on the victim's subdomain. Easy, common, and
pairs directly with recon output. Read + reason; claim only within program rules.

## How it happens

Subdomain `blog.target.com` CNAMEs to `target.github.io` / a Heroku app / an S3
bucket that was deleted. The service is free to re-register → you claim it and own
the subdomain (cookies scoped to `*.target.com`, OAuth/SSO trust, phishing, XSS
against parent, bypassing SPF/CSP allowlists).

## Detection (from recon)

1. From `subs.txt`/`resolved.txt`, pull CNAMEs: `dnsx -l subs -cname -resp`.
2. Probe the fingerprint response: `httpx -l subs -title -sc` → look for provider
   error pages: "There isn't a GitHub Pages site here", "NoSuchBucket", "no such
   app" (Heroku), "Fastly error: unknown domain", "The specified bucket does not
   exist", "Do you want to register *.wordpress.com", Shopify/Zendesk/Surge/
   Netlify/Readme/Unbounce/Tumblr/Desk/Statuspage errors.
3. Automated fingerprints: **subzy**, **nuclei** `takeovers` templates,
   **can-i-take-over-xyz** fingerprint DB, **subjack**, **dnsReaper**.

## Confirm before claiming

Match the CNAME target service + the exact edge-case fingerprint in
can-i-take-over-xyz (some providers are *not* takeoverable, or need extra steps).
NS-record takeover (dangling delegation) is higher impact but rarer.

## Safe PoC

Claim the resource on the third-party service and serve a **harmless** proof page
(your H1 handle / a unique token) at the subdomain path — nothing malicious, no
cookie capture. Screenshot DNS + your control. Then release if the program asks.
Follow program rules: some forbid actually registering; a strong fingerprint +
explanation may suffice — check the policy.

## Impact framing

Cookie theft (`*.target.com` scoping), OAuth `redirect_uri` abuse, CSP/SPF
allowlist bypass, phishing on a trusted domain, XSS against parent app.

## Tools

**subzy**, **nuclei -t takeovers**, **subjack**, **dnsReaper**, `dnsx -cname`,
can-i-take-over-xyz repo. Re-run periodically — new dangling records appear as
infra churns (persistent recon).

## References (current)

- EdOverflow — can-i-take-over-xyz (canonical fingerprint DB).
- PortSwigger / HackerOne disclosed takeover reports.
