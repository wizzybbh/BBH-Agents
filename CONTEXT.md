# CONTEXT — BB AI Agents

Glossary for a suite of AI capabilities that support bug bounty hunting on
HackerOne/BugCrowd using Jason Haddix's *The Bug Hunter's Methodology* (TBHM).
This file is a glossary only — no implementation details, no plans.

## Core vocabulary

- **Skill** — a reusable *procedure/playbook* an AI loads on demand and runs in
  its current context (e.g. `/scope`, `/triage`). Not an isolated worker.
- **Subagent** — a *separate worker with its own context window* that a bounded
  job is delegated to (e.g. "enumerate this ASN, return a host list"). Used for
  parallel, noisy, or long-running work. Distinct from a Skill.
- **Self-contained skill** — a skill shipped as a standalone folder
  (`SKILL.md` + any bundled knowledge) that works with zero external
  dependencies, whether symlinked into `~/.claude/skills/` or pasted into a
  fresh chat. The unit of distribution. (Supersedes the earlier "thin adapter"
  idea — see ADR 0001.)
- **Knowledge base** — the repo's `knowledge/` folder: deep reference docs
  (e.g. the framework→bug-class matrix, triage signals, TBHM recon-topic
  notes). The *authoring source*. Skills bundle the essential slices they need
  so they never break when used standalone; the Knowledge base holds the full
  versions and is where an edit starts.

## Domain vocabulary (from existing /scope and /triage skills)

- **Program** — a bug bounty engagement on a platform (HackerOne/BugCrowd) with
  a policy (rules truth) and a scope CSV (asset truth).
- **Scope** — the authoritative set of assets a Program authorizes testing on.
- **Recon Target** — an asset that authorizes *subdomain enumeration* — i.e. a
  **wildcard** root (`*.example.com`). A fixed in-scope URL is NOT a Recon
  Target and does not authorize enumerating its parent.
- **Target** (in `/triage`) — a specific host/URL selected to hunt on, ranked
  hot→cold by stacked signals. Distinct from Recon Target.
- **Profile** — the app-analysis output for one chosen Target: tech
  fingerprint, framework→bug-class map, content-discovery plan, auth model,
  and notable endpoints. The Day-2 "understand the app" artifact.
- **Hunt plan** — a per-bug-class test plan for one Target, built from its
  Profile and its Caido traffic, listing exact payloads/requests for the
  operator to fire manually. The AI never sends them.
- **Recon mode** — chosen at the start of a recon run: **automated** (the AI
  runs the enumeration pipeline on the VPS) or **manual** (the operator runs
  their own pipeline; the AI only reads/filters the outputs).

## Guardrails (resolved decisions, not glossary — see docs/adr/)

- **Human stays the trigger.** No skill sends attack traffic at a live target.
  The AI reads Caido traffic and hands the operator exact payloads to fire.
- **Portable Core is the single source of truth.** Adapters (SKILL.md /
  AGENTS.md) carry no methodology; they point at the Core.
- **Scope is enforced everywhere.** Only wildcard Recon Targets authorize
  subdomain enumeration; nothing out-of-scope is ever promoted as a Target.
