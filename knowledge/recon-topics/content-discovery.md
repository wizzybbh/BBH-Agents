# Content & Parameter Discovery

Once a host is live, find the hidden paths, files, and parameters where bugs live.
The root page rarely matters — the app is in its paths. Honor program rate rules.

## Directory / file discovery

```
feroxbuster -u https://host -w raft-large-directories.txt -r -t 30 -x php,json,bak,old,zip
ffuf -u https://host/FUZZ -w wordlist -recursion -recursion-depth 2 -mc all -fc 404
```
- Wordlists: **SecLists** (`raft-*`, `content_discovery_all`), **Assetnote**
  wordlists (best coverage), tech-specific lists (per fingerprint from `/profile`).
- Match on size/words/lines, not just status (filter soft-404s with `-ac`/`-fs`).
- Recurse into discovered dirs. Try common backups/config:
  `.git/ .env .DS_Store backup.zip config.php.bak swagger.json /actuator`.

## Archive & crawl URLs (passive + active)

```
gau --subs host | anew urls.txt
katana -u https://host -jc -kf all -d 3 | anew urls.txt      # -jc parses JS
waybackurls host | anew urls.txt
```
**Auth crawl** (login cookies) with katana → 2–3× the surface behind auth.
Then pattern-mine (see js-analysis.md and the `url-miner` subagent):
`cat urls.txt | gf ssrf|redirect|sqli|lfi|xss|idor`.

## Parameter discovery

```
arjun -u "https://host/endpoint" -m GET,POST -oJ params.json     # brute hidden params
paramspider -d host                                              # from archives
x8 -u "https://host/endpoint" -w params.txt                      # heuristic
```
Hidden params reveal debug flags, admin toggles, injectable inputs. Combine with
`qsreplace` to swap values across all collected URLs for mass testing (as leads).

## API route discovery

- **Kiterunner**: `kr scan https://api.host -w routes-large.kite` (API-aware,
  handles method + content-type — far better than dir brute for APIs).
- OpenAPI/Swagger: fetch `/swagger.json`, `/openapi.json`, `/api-docs`, `/v2/api-docs`
  → import to Caido/Postman, enumerate every operation.
- GraphQL: introspection → schema (see `bug-classes/graphql.md`).

## Virtual hosts

`ffuf -u https://IP -H "Host: FUZZ.target.com" -w vhosts -fs <baseline>` — finds
apps served only by Host header (internal/staging on shared IPs).

## Output

Merged, de-duped `urls.txt` + discovered paths/params per host → `url-miner`
subagent for clustering → `/triage`/`/profile`.

## Tools

feroxbuster, ffuf, dirsearch, gau, katana, waybackurls, gf, qsreplace, arjun,
paramspider, x8, kiterunner, SecLists/Assetnote wordlists, anew.

> Sources: [amrelsagaei Methodology 2025](https://github.com/amrelsagaei/Bug-Bounty-Hunting-Methodology-2025)
