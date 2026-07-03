# JavaScript Analysis

Modern SPAs ship endpoints, secrets, and hidden logic to the client. JS mining is
one of the highest-ROI recon steps — it maps the API you'll actually attack. Read
+ reason.

## Collect JS

```
cat live.txt | katana -jc -kf all -d 3 | grep '\.js' | anew js_urls.txt
cat live.txt | gau --subs | grep '\.js' | anew js_urls.txt
subjs -i live.txt | anew js_urls.txt          # or getJS
```
Download for offline parsing; include inline `<script>` from HTML too.

## Extract endpoints & routes

- **jsluice** (modern, best): `cat js_urls.txt | jsluice urls` and `jsluice secrets`.
- **LinkFinder** / **xnLinkFinder**: pull relative + absolute endpoints, then
  resolve against the host → new attack surface & hidden API routes.
- Feed discovered endpoints back into content-discovery / `/profile`.

## Hunt secrets

- **SecretFinder**, **Mantra**, **trufflehog**/**gitleaks** (run on JS files),
  `gf` patterns (`aws-keys`, `firebase`, `jwt`, `s3-buckets`).
- Look for: API keys (Google Maps/Stripe/Firebase/AWS/Algolia/Sentry DSN), OAuth
  client secrets, hardcoded creds, internal hostnames, feature flags, admin routes,
  GraphQL schema, S3 bucket names, third-party tokens.
- **Validate carefully** — confirm a key is live with a single minimal call; don't
  abuse it (see `bug-classes/secrets-info-disclosure.md`).

## Source maps (goldmine)

If `.js.map` files ship in prod, reconstruct original source (component names,
comments, unminified logic, sometimes more endpoints/secrets):
`sourcemapper -url https://host/app.js.map -output src/` or `unwebpack-sourcemap`.
Even without `.map`, `webcrack`/`wakaru` can partially de-bundle.

## Diff over time

Re-pull JS periodically; diff to catch **new endpoints/features/keys** shipped in
a release before they're hardened (`anew`/git-tracked JS snapshots). Persistent JS
recon surfaces fresh bugs on every deploy.

## Output

`endpoints.txt` (→ content-discovery, `/profile`, `url-miner`), `secrets.txt`
(→ validate → `/report`).

## Tools

katana (`-jc`), gau, subjs/getJS, **jsluice**, LinkFinder/xnLinkFinder,
SecretFinder, Mantra, trufflehog, gitleaks, gf, sourcemapper/unwebpack, webcrack.

> Sources: [Leaked secrets via nuclei/subfinder/katana/httpx](https://medium.com/@mohamedsinger837/from-recon-to-sensitive-key-exposure-finding-leaked-secrets-using-nuclei-subfinder-katana-429d2ce705ae), [amrelsagaei Methodology 2025](https://github.com/amrelsagaei/Bug-Bounty-Hunting-Methodology-2025)
