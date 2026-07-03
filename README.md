# BB AI Agents

A tight suite of AI **skills** and **subagents** for bug bounty hunting on
HackerOne / BugCrowd, built around Jason Haddix's *The Bug Hunter's Methodology*
(TBHM). Designed to run where your recon lives — on your Ubuntu VPS — and to be
portable across Claude Code, Codex, or any assistant.

**Authorized testing only.** Everything here reads and reasons. Per
[ADR 0002](docs/adr/0002-human-stays-the-trigger.md), no skill fires attack
traffic — the AI hands you exact payloads; *you* pull the trigger.

## The suite

| Skill | What it does |
|---|---|
| `/scope` | Program policy + scope CSV → clean `scope.txt` operating doc |
| `/recon` | Runs the enumeration pipeline (**automated mode**) or reads/filters your own recon output (**manual mode**) |
| `/triage` | Recon files → ranked hot→cold target shortlist with why + what to test |
| `/profile` | One chosen host → app-analysis profile: tech fingerprint → bug-class priorities, content-discovery plan, auth model |
| `/hunt` | Target + its Caido traffic → per-bug-class test plan with exact payloads to fire yourself |
| `/report` | A confirmed finding → H1/Bugcrowd submission (title, CVSS, repro, impact) |

| Subagent | What it does |
|---|---|
| `url-miner` | Chews huge gau/katana dumps → clustered interesting endpoints/params |
| `caido-reader` | Pulls & summarizes Caido traffic for one host |
| `recon-runner` | Runs the noisy multi-tool recon pipeline in its own context |

## Knowledge library (the depth)

`knowledge/` is the deep, current reference the skills draw on (`install.sh`
symlinks it to `~/.claude/bb-knowledge/` so skills find it anywhere):

- **`knowledge/bug-classes/`** — 18 per-class playbooks (IDOR/BOLA, SSRF, GraphQL,
  JWT/auth, XSS, SSTI, SQLi/NoSQLi, LFI, XXE, command injection, file upload,
  prototype pollution, cache poisoning, CORS/CSRF, open redirect, subdomain
  takeover, race/logic, secrets/info-disclosure). Each: where it lives → how to
  find → current payloads &
  bypasses → escalation → safe PoC → tools → references. `/hunt` loads the class
  playbook; `/profile` uses the matrix to pick classes.
- **`knowledge/framework-bugclass-matrix.md`** — fingerprint → which classes to
  prioritize, across React/Vue/Angular/jQuery, Node/Express, ASP.NET/Django/Flask/
  Next/Laravel, plus WordPress/Spring/Rails/API-first.
- **`knowledge/recon-topics/`** — TBHM Day-1 playbooks with current tooling
  (subdomain enum, ASN/acquisitions scope expansion, content/param discovery, JS
  analysis, cloud, GitHub dorking). `/recon` draws on these.

Content is current as of mid-2026 (e.g. IMDSv2 parser-confusion SSRF, Next.js SSRF
CVEs, JWT alg-confusion/kid/jku, GraphQL batching, single-packet race attacks,
server-side prototype pollution). Skills bundle inline essentials so they still
work standalone ([ADR 0001](docs/adr/0001-self-contained-skills.md)).

## Install

Each skill is a self-contained folder; each subagent is a single file. To wire
them into Claude Code (Mac or VPS):

```bash
git clone https://github.com/wizzybbh/BBH-Agents ~/BBH-Agents
cd ~/BBH-Agents
./install.sh          # symlinks skills → ~/.claude/skills, agents → ~/.claude/agents,
                      # and knowledge/ → ~/.claude/bb-knowledge
```

`git pull` keeps everything current — symlinks mean no re-copying.

**Ad hoc / other assistants:** paste a skill's `SKILL.md` into any chat and say
"save this as a skill." It works standalone.

## Config

Copy `.env.example` → `.env` (gitignored) and fill in your VPS host, Caido token,
and HackerOne handle/User-Agent. Per-target working files live on the VPS at
`~/targets/<program>/`.

## Typical flow

```
/scope   → scope.txt for the program
/recon   → (automated: run pipeline)  or  (manual: you run yours; AI reads output)
/triage  → ranked shortlist of hosts to hunt
/profile → deep app-analysis on the top host(s)
/hunt    → per-bug-class payloads for the juicy target (fire them in Caido yourself)
/report  → package the confirmed finding for submission
```
