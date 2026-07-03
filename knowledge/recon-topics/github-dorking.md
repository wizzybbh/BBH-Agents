# GitHub Recon & Dorking

Source-code recon surfaces leaked secrets, internal hostnames, and hidden
endpoints — some of the fastest criticals. Only report leaks tied to in-scope
assets; never abuse a credential.

## Map the org's code footprint

- Org repos: `github.com/<org>` → repos, members, forks.
- **Employee repos & gists** — devs leak work secrets in personal repos; pivot
  from org members / commit-author emails.
- Old **commit history** and deleted-but-cached content (secrets removed in HEAD
  often live in history).

## Dork the code

Search GitHub code for org identifiers + secret patterns:
```
"target.com" password        "target.com" api_key
org:TargetOrg secret         "internal.target.com"
"target.com" AKIA            "target.com" BEGIN RSA PRIVATE KEY
filename:.env target         "target.com" jdbc  "target.com" mongodb://
```
Combine domain/brand with: `password, secret, token, apikey, api_key, aws_access,
AKIA, private_key, authorization, bearer, jdbc, connectionstring, .env, config,
staging, internal, admin`.

## Tooling (automate it)

- **trufflehog** `github --org=TargetOrg` — verified-secret scanning across org + history.
- **gitleaks** on cloned repos.
- **github-subdomains** — new subdomains from code (feed to subdomain-enum).
- **gitdorks_go** / **GitDorker** — run dork lists at scale with a token.
- **git-hound**, **shhgit**-style live monitoring.
- Use a GitHub token (`$GITHUB_TOKEN`) — raises rate limits and search access.

## What to do with a hit

1. Confirm it's tied to an **in-scope** asset.
2. Validate the secret is **live** with one minimal, non-destructive check
   (e.g. identity/whoami call) — do NOT pivot, exfiltrate, or use it further.
3. Capture: file/commit URL, secret type, proof of validity, affected asset.
4. → `/report` (impact = what the key unlocks; recommend rotation).

## Persistent monitoring

Watch the org (and key employees) continuously — new commits leak new secrets.
Cron trufflehog/gitdorks weekly; alert on new hits.

## Tools

trufflehog, gitleaks, github-subdomains, gitdorks_go/GitDorker, git-hound, GitHub
code search, GitHub API + token.

> Sources: [amrelsagaei Methodology 2025](https://github.com/amrelsagaei/Bug-Bounty-Hunting-Methodology-2025)
