# Recon-Topics Library (TBHM Day 1)

Deep playbooks for the reconnaissance phase, mapped to TBHM Day-1 topics
(Scope → ASNs/Acquisitions → Subdomains → Cloud → GitHub → Content/JS →
Screenshots). `/recon` and `recon-runner` draw on these; `/triage` consumes the
output. Enumerate ONLY in-scope **wildcard Recon Targets** (see
[../../CONTEXT.md](../../CONTEXT.md)) and honor program rules.

## The pipeline (current tooling, mid-2026)

```
scope roots (*.target.com)
  │  scope expansion → asn-acquisitions.md   (find more roots first!)
  ▼
passive subdomains ─ subfinder -all -recursive · amass enum -passive · crt.sh · github-subdomains
  │  (+ active if allowed) ─ puredns/shuffledns + massdns · dnsx · ffuf vhost
  ▼
resolve ─ dnsx -resp -a -cname
  ▼
probe HTTP ─ httpx -sc -title -tech-detect -cdn -location -o live_detailed.txt
  ▼
crawl + urls ─ katana -jc (auth crawl w/ cookies = 2-3x surface) · gau --subs · waybackurls
  ▼
content discovery ─ feroxbuster/ffuf   |   JS analysis ─ jsluice/LinkFinder/SecretFinder
  ▼
screenshots ─ gowitness/aquatone   →   /triage
```

## Topic playbooks

| File | Topic |
|---|---|
| [asn-acquisitions.md](asn-acquisitions.md) | Scope expansion: ASNs, acquisitions, reverse-whois, favicon, orgs |
| [subdomain-enum.md](subdomain-enum.md) | Passive + active subdomain discovery, resolving, probing |
| [content-discovery.md](content-discovery.md) | Dirs/files, parameters, virtual hosts, API routes |
| [js-analysis.md](js-analysis.md) | Endpoints & secrets from JavaScript, source maps |
| [cloud.md](cloud.md) | S3/GCS/Azure buckets, cloud ranges, metadata surfaces |
| [github-dorking.md](github-dorking.md) | Org/employee repos, commit history, leaked secrets |

## Principles

- **Expand scope before enumerating** — find every wildcard root you're allowed
  (acquisitions, ASNs) so recon covers the real attack surface, not just the obvious apex.
- **Passive first** (no direct traffic), then active only where program rules allow.
- **Persistent recon** — infra churns; re-run on a schedule (cron) and diff with
  `anew` to catch new subdomains/takeovers over time.
- **Scope is law** — drop out-of-scope + 3rd-party at every stage.
