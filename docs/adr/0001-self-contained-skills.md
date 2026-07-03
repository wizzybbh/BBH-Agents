# Self-contained skills over thin adapters

We ship each skill/subagent as a **standalone folder** (`SKILL.md` + any bundled
knowledge) that works with zero external dependencies — symlinked into
`~/.claude/skills/` *or* pasted into a fresh chat. We keep a repo `knowledge/`
folder as the authoring source of deep reference (e.g. the framework→bug-class
matrix); skills bundle the essential slices they need.

## Considered options

- **Thin adapters + portable core** (originally chosen): DRY, one source of
  truth, but a skill file is a wrapper that references `core/` at a relative
  path. Installing then means "clone the repo," and pasting a single file into
  a chat produces a *broken* skill whose core isn't present.
- **Self-contained skills** (chosen): the operator installs by pasting a file or
  symlinking one folder, with no hidden dependencies. Robust and portable across
  Claude/Codex/any assistant.
- **Fat skills assembled by a build step**: DRY source + standalone artifact,
  but adds a build toolchain to maintain — too heavy for a solo operator.

## Consequences

- Shared knowledge (the bug-class matrix, triage signals) is **duplicated** into
  the 2–3 skills that use it. A change means editing those few files. Accepted
  as the cost of portability; the shared assets change rarely.
- The repo's `knowledge/` holds the canonical full versions; when they change,
  update `knowledge/` first, then re-sync the bundled slices.
