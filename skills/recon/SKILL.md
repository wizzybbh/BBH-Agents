---
name: recon
description: Run TBHM Day-1 recon on a program's wildcard roots (automated mode) OR read and filter recon output the user generated themselves (manual mode). Use when the user runs /recon, wants to enumerate a scope, or points at existing recon output to be organized. Always asks which mode first.
---

# /recon — Enumeration pipeline OR read/filter the user's own recon

Two modes. **Always ask which one before doing anything.** Authorized-testing
context only; runs on the VPS where recon lives.

```
Which mode?
  (A) AUTOMATED — I run the enumeration pipeline on the VPS for you.
  (B) MANUAL    — you run your own recon; I read, filter, and organize the output.
```

Enforce scope from `~/targets/<program>/scope.txt` (from `/scope`) in **both**
modes: enumerate ONLY wildcard **Recon Targets**; never touch out-of-scope or
3rd-party hosts. If no scope.txt exists, tell the user to run `/scope` first.

## Mode A — Automated

Confirm the program slug and the in-scope wildcard roots, then run the pipeline
against those roots only, writing into `~/targets/<slug>/recon/`. Honor program
rules (rate posture from scope.txt; no brute-force where excluded; required UA).
Announce each stage; on any tool being absent, say so and continue.

**Preferred:** if the repo's `scripts/recon-pipeline.sh` is present, run it — it
does the whole chain in one command, is passive by default, and uses `anew` to
surface only NEW subdomains:
```
scripts/recon-pipeline.sh -p <slug>                      # passive
scripts/recon-pipeline.sh -p <slug> --active --takeover  # only if program allows active DNS
```
Run `scripts/recon-pipeline.sh --check` first to see installed tools. Only pass
`--active` when scope.txt confirms active DNS brute-force is allowed. If the
script isn't present, execute the stages below manually via `recon-runner`.

For full per-stage depth (current tool commands, flags, wordlists), read the
**recon-topics library** at `~/.claude/bb-knowledge/recon-topics/` (symlinked by
`install.sh`; else the repo's `knowledge/recon-topics/`): `subdomain-enum.md`,
`asn-acquisitions.md` (run scope expansion FIRST), `content-discovery.md`,
`js-analysis.md`, `cloud.md`, `github-dorking.md`. Fall back to the inline
pipeline below if the library isn't present.

Pipeline (TBHM Day-1 order — adapt to installed tools):
1. **Passive subdomains** — `subfinder`, `amass enum -passive`, `assetfinder` → `subs.txt` (sort -u).
2. **(Optional) brute/permute** — `puredns`/`dnsx` with a wordlist, `dnsgen` — ONLY if program rules allow active DNS.
3. **Resolve** — `dnsx` → `resolved.txt`.
4. **Probe HTTP** — `httpx -sc -title -tech-detect -o live_detailed.txt` (+ plain `live.txt`).
5. **URLs/endpoints** — `gau`, `katana`, `waybackurls` per live host → `urls.txt`.
6. **Screenshots** — `gowitness`/`aquatone` over `live.txt` (optional).

Uses the `recon-runner` subagent for the noisy multi-tool stages so the main
context stays clean; it returns a summary + the output file paths.

Do **not** run vuln scanners or attack tooling here — recon only. After the run,
hand off: "Recon done — N live hosts. Run `/triage` to rank them."

## Mode B — Manual (read + filter)

The user ran their own pipeline. Read their output files in place (ask for the
dir; default `~/targets/<slug>/recon/`) and organize:
- De-dupe and scope-filter host lists against scope.txt (drop OOS + 3rd-party).
- Summarize what's present: # subs, # live, status-code spread, tech spread.
- Surface obvious clusters (env prefixes, interesting titles/tech) as a preview.
- Point large URL dumps at the `url-miner` subagent for clustering.

Never send requests in Mode B — only read/filter files.

## Output (both modes)

```
### RECON: <program>  |  mode: <A/B>  |  <today>
scope roots: <*.x ...>
subdomains: <N>   live: <N>   (files: recon/subs.txt, recon/live_detailed.txt, recon/urls.txt)
status spread: 200:<n> 401/403:<n> 3xx:<n> 5xx:<n>
tech spread: <top techs + counts>
notable at a glance: <env-prefixed / admin / api / staging hosts, top 5>
⚠ scope drops: <count OOS/3rd-party removed>
▶ next: /triage recon/live_detailed.txt   (then /profile the hot hosts)
```

## Guardrails

- **Ask mode first, every time.** Never assume automated.
- **Scope is law** — wildcard roots only; honor rate/brute-force rules from scope.txt.
- **Recon ≠ attack.** No nuclei/vuln-scan/exploitation in this skill.
- Keep the summary ~one screen; the files hold the detail.
