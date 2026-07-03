# Subdomain Enumeration

Find every host under an in-scope wildcard root. Coverage wins bounties — a
forgotten `dev-`/`legacy-` host is where the bugs are. Enumerate ONLY wildcard
Recon Targets.

## 1. Passive (no direct traffic to target)

```
subfinder -d target.com -all -recursive -silent -o subfinder.txt
amass enum -passive -d target.com -o amass.txt
curl -s "https://crt.sh/?q=%25.target.com&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u
github-subdomains -d target.com -t $GITHUB_TOKEN -o gh.txt
```
Also: **Chaos** (ProjectDiscovery dataset), certificate transparency (crt.sh,
censys), **assetfinder**, threat-intel feeds, VirusTotal/SecurityTrails/Shodan
(API keys in subfinder config boost sources a lot — configure `~/.config/subfinder/provider-config.yaml`).

Merge: `cat *.txt | sort -u | anew all_subs.txt`.

## 2. Active (only if program rules allow active DNS)

- **DNS brute-force**: `puredns bruteforce best-dns-wordlist.txt target.com -r resolvers.txt`
  or `shuffledns -d target.com -w wordlist.txt -r resolvers.txt`. Use fresh
  resolvers (`dnsvalidator`/`trickest resolvers`).
- **Permutation**: `dnsgen all_subs.txt | puredns resolve -r resolvers.txt`,
  or **gotator**/**altdns/ripgen** for mutations (`dev`, `staging`, `-uat`, numbers).
- **VHost fuzzing** (same IP, different Host header):
  `ffuf -u https://TARGET_IP -H "Host: FUZZ.target.com" -w wordlist -fs <baseline>`.

## 3. Resolve & dedupe

```
dnsx -l all_subs.txt -a -resp -cname -o resolved.txt     # keep CNAMEs for takeover check
```
Note wildcards DNS (`*.target.com` resolving everything) → filter false positives
with `puredns`'s wildcard detection.

## 4. Probe HTTP(S)

```
httpx -l resolved.txt -sc -title -tech-detect -cdn -location -web-server \
      -p 80,443,8080,8443,8000,3000 -o live_detailed.txt
grep -oP 'https?://[^ ]+' live_detailed.txt | sort -u > live.txt
```
`-cdn` flags CDN/WAF IPs (don't port-scan those). `-favicon` for favicon-hash
pivoting (find related hosts via shodan `http.favicon.hash:`).

## 5. Feed forward

`resolved.txt` (+ CNAMEs) → **subdomain-takeover** check (subzy/nuclei).
`live_detailed.txt` → `/triage`. `live.txt` → content-discovery, katana, gau.

## Persistent recon

Cron the passive stage; `anew` to append only new hosts and alert on them
(new subdomain = fresh, un-hunted surface, and a takeover-window). This is where
solo hunters win over time.

## Tools

subfinder, amass, assetfinder, github-subdomains, chaos, crt.sh, puredns,
shuffledns, massdns, dnsx, dnsgen/gotator, ffuf (vhost), httpx, anew.

> Sources: [amrelsagaei Methodology 2025](https://github.com/amrelsagaei/Bug-Bounty-Hunting-Methodology-2025), [Persistent Recon (Ravi Sharma)](https://ravi73079.medium.com/2025-bug-bounty-methodology-toolsets-and-persistent-recon-d991e39e52ce)
