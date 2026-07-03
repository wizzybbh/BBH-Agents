# Secrets & Information Disclosure

Often the fastest bounty: exposed keys, source, configs, and debug endpoints found
in JS, git, backups, and misconfigured storage. Read + reason; report the leak,
don't abuse the credential.

## JavaScript analysis (biggest modern source)

Bundlers ship secrets and endpoints to the client.
- Pull JS: `katana -jc`, `gau|grep '\.js'`, `subjs`, `getJS`.
- Extract: **LinkFinder**/**xnLinkFinder** (endpoints), **SecretFinder**,
  `gf` patterns (`aws-keys`, `urls`), **trufflehog**/**gitleaks** on JS,
  **mantra**, **jsluice** (endpoints + secrets, modern), source-map extraction
  (`.js.map` → original source via **sourcemapper**/`unwebpack`).
- Look for: API keys, hardcoded creds, internal hostnames/APIs, hidden routes,
  feature flags, GraphQL schema, S3 buckets, third-party tokens, dev comments.

## Exposed sensitive files / paths (content discovery)

`.git/` (dump with **git-dumper** → full source & history secrets), `.env`,
`.svn/`, `.DS_Store` (**ds_store_exp**), backups (`.bak .old .zip .tar.gz .sql`),
`/config`, `/actuator/*` (Spring: `/env`, `/heapdump`, `/mappings`), `/debug`,
`/server-status`, `/phpinfo.php`, `swagger.json`/`openapi.json`, `/.well-known/`,
`robots.txt`/`sitemap.xml` (path leaks), `/wp-json/`, `/_next/`.

## Cloud storage misconfig

- **S3**: list/read/write on `bucket.s3.amazonaws.com`; find buckets in JS/HTML/DNS;
  test `aws s3 ls s3://bucket --no-sign-request`; public write → defacement/supply-chain.
- **GCS/Azure Blob** equivalents; **firebase** open DB
  (`<proj>.firebaseio.com/.json`).

## Source-code & repo recon (GitHub dorking)

Org repos, employee repos, commit history, gists: search `target.com`, API-key
patterns, `password`, `secret`, `internal`, `.env`, staging URLs.
Tools: **trufflehog**, **gitleaks**, **github-subdomains**, **gitdorks_go**,
GitHub code search dorks.

## Other disclosure

Verbose errors / stack traces (framework, path, versions), debug mode on
(Django `DEBUG=True` → settings dump; Flask Werkzeug console → RCE), `X-Powered-By`/
version headers, GraphQL introspection, directory listing, source maps in prod.

## Validate & report responsibly

Confirm a leaked key is **live** minimally (a single low-impact read/`sts
get-caller-identity`-style check) to prove impact — do **not** pivot, exfiltrate,
or use it destructively. Report the exposure + demonstrated validity + rotation advice.

## Tools

**jsluice, SecretFinder, LinkFinder, trufflehog, gitleaks, git-dumper,
sourcemapper, nuclei (exposures/ templates), gf patterns, ffuf** (backup/config
discovery), **cloud_enum**/**s3scanner**.

## References (current)

- ProjectDiscovery nuclei `exposures/` & `misconfiguration/` templates.
- TruffleHog / Gitleaks docs; PortSwigger information-disclosure labs.

> Sources: [Leaked secrets via nuclei/subfinder/katana/httpx](https://medium.com/@mohamedsinger837/from-recon-to-sensitive-key-exposure-finding-leaked-secrets-using-nuclei-subfinder-katana-429d2ce705ae)
