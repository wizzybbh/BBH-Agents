#!/usr/bin/env bash
# doctor.sh — health check for a BBH-Agents install (works on VPS or laptop).
# Verifies: Claude Code, git freshness, skill/agent/knowledge symlinks, .env,
# and the recon toolchain. Read-only; changes nothing.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
CLA="${CLAUDE_HOME:-$HOME/.claude}"
c(){ printf '\033[%sm%s\033[0m\n' "$1" "$2"; }
ok(){ c '1;32' "[+] $*"; }
warn(){ c '1;33' "[!] $*"; }
err(){ c '1;31' "[x] $*"; }
have(){ command -v "$1" >/dev/null 2>&1; }
FAIL=0

echo "== BBH-Agents doctor =="
echo "repo:  $REPO"
echo "claude home: $CLA"
echo

# 1. Claude Code
have claude && ok "claude CLI: $(claude --version 2>/dev/null | head -1)" || warn "claude CLI not on PATH (install or fix PATH)"

# 2. git freshness vs origin
if git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$REPO" fetch -q origin 2>/dev/null || warn "git fetch failed (offline?)"
  L=$(git -C "$REPO" rev-parse --short HEAD 2>/dev/null)
  R=$(git -C "$REPO" rev-parse --short origin/main 2>/dev/null || echo "?")
  [ "$L" = "$R" ] && ok "git up to date ($L)" || { warn "git differs: local $L vs origin/main $R — run: git pull"; }
else err "not a git repo"; FAIL=1; fi
echo

# 3. skills
echo "-- skills (should all be symlinks into this repo) --"
for s in scope recon triage profile hunt report; do
  p="$CLA/skills/$s"
  if [ -L "$p" ] && readlink "$p" | grep -q "$REPO"; then ok "$s"
  elif [ -L "$p" ]; then warn "$s → symlink to a DIFFERENT path: $(readlink "$p")"
  elif [ -e "$p" ]; then err "$s → REAL dir blocking the repo link. Fix: mv \"$p\" ~/.claude/skills/_backup_pre_bbh/ ; then ./install.sh"; FAIL=1
  else err "$s missing — run ./install.sh"; FAIL=1; fi
done
echo

# 4. agents
echo "-- agents --"
for a in caido-reader recon-runner url-miner; do
  p="$CLA/agents/$a.md"
  { [ -L "$p" ] && readlink "$p" | grep -q "$REPO"; } && ok "$a" || { err "$a not linked — run ./install.sh"; FAIL=1; }
done
echo

# 5. knowledge
echo "-- knowledge base --"
if [ -L "$CLA/bb-knowledge" ] && [ -d "$CLA/bb-knowledge" ]; then
  bc=$(ls "$CLA"/bb-knowledge/bug-classes/*.md 2>/dev/null | grep -vc README || echo 0)
  rt=$(ls "$CLA"/bb-knowledge/recon-topics/*.md 2>/dev/null | grep -vc README || echo 0)
  ok "bb-knowledge linked  (bug-classes: $bc, recon-topics: $rt)"
else err "bb-knowledge not linked — run ./install.sh"; FAIL=1; fi
echo

# 6. .env
echo "-- config (.env) --"
if [ -f "$REPO/.env" ]; then
  set -a; . "$REPO/.env" 2>/dev/null; set +a
  [ -n "${TESTING_USER_AGENT:-}" ] && ok "TESTING_USER_AGENT set" || warn "TESTING_USER_AGENT blank (many programs REQUIRE it)"
  [ -n "${GITHUB_TOKEN:-}" ] && ok "GITHUB_TOKEN set" || warn "GITHUB_TOKEN blank (github-subdomains/dorking limited)"
  case "${CAIDO_API_TOKEN:-}" in
    *[Bb]earer*|*" "*) err "CAIDO_API_TOKEN has a 'Bearer'/space — store the raw token only";;
    "") : ;;  # blank is correct on the VPS
    *) ok "CAIDO_API_TOKEN set (raw)";;
  esac
else warn ".env missing — cp .env.example .env"; fi
echo

# 7. recon toolchain
echo "-- recon toolchain --"
if [ -x "$REPO/scripts/recon-pipeline.sh" ]; then
  "$REPO/scripts/recon-pipeline.sh" --check 2>/dev/null | sed '/^Install/,$d'
else err "scripts/recon-pipeline.sh missing/not executable"; FAIL=1; fi
have massdns && ok "massdns present (active brute ready)" || warn "massdns absent (active brute disabled; passive recon is unaffected)"
echo

[ "$FAIL" = 0 ] && ok "DOCTOR: core is healthy — you're good to run /scope, /recon, /triage" \
                || err "DOCTOR: fix the [x] items above, then re-run"
