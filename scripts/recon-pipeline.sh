#!/usr/bin/env bash
#
# recon-pipeline.sh — TBHM Day-1 enumeration for in-scope wildcard roots.
#
# Passive by default (no direct brute traffic). Active DNS brute/permutation only
# with --active. Writes into <targets>/<slug>/recon/ and uses `anew` so re-runs
# surface only NEW subdomains (persistent recon). Honors a required User-Agent.
#
# Authorized-testing only. Enumerate ONLY wildcard roots the program authorizes.
# See ADR 0002 — this does RECON only; no vuln scanning / attack traffic.
#
# Usage:
#   ./recon-pipeline.sh example.com                 # one root, passive
#   ./recon-pipeline.sh -l roots.txt                # many roots from a file
#   ./recon-pipeline.sh -p acme                     # roots from scope.txt of program 'acme'
#   ./recon-pipeline.sh example.com --active --screenshots --takeover
#   ./recon-pipeline.sh -p acme -w ~/wl/dns.txt      # active brute w/ a per-run wordlist
#   ./recon-pipeline.sh --check                     # just report which tools are installed
#
#   -w/--wordlist and -r/--resolvers override .env per run (RECON_WORDLIST /
#   RECON_RESOLVERS). Passing -w turns on active mode. Leave the env blank and
#   pass -w only when you want active DNS brute — /recon will ask you for it.
#
# Config via env or .env (see .env.example): VPS_TARGETS_DIR, TESTING_USER_AGENT,
#   GITHUB_TOKEN, RECON_WORDLIST, RECON_RESOLVERS, RECON_RATE.
set -uo pipefail

# ---------- load .env if present (repo root) ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/../.env" ] && set -a && . "$SCRIPT_DIR/../.env" && set +a

# ---------- defaults ----------
TARGETS_DIR="${VPS_TARGETS_DIR:-$HOME/targets}"
TARGETS_DIR="${TARGETS_DIR/#\~/$HOME}"
UA="${TESTING_USER_AGENT:-}"
RATE="${RECON_RATE:-50}"                       # req/s cap for polite probing/crawl
WORDLIST="${RECON_WORDLIST:-}"                  # for --active DNS brute
RESOLVERS="${RECON_RESOLVERS:-}"               # trusted resolvers file for --active
ACTIVE=0; SHOTS=0; TAKEOVER=0; CHECK=0
ROOTS=(); ROOTS_FILE=""; PROGRAM=""

# ---------- pretty logging ----------
c(){ printf '\033[%sm%s\033[0m' "$1" "$2"; }
log(){ echo "$(c '1;34' '[*]') $*"; }
ok(){  echo "$(c '1;32' '[+]') $*"; }
warn(){ echo "$(c '1;33' '[!]') $*" >&2; }
err(){ echo "$(c '1;31' '[x]') $*" >&2; }
have(){ command -v "$1" >/dev/null 2>&1; }

# ---------- arg parsing ----------
while [ $# -gt 0 ]; do
  case "$1" in
    -l|--list) ROOTS_FILE="$2"; shift 2;;
    -p|--program) PROGRAM="$2"; shift 2;;
    -w|--wordlist) WORDLIST="$2"; ACTIVE=1; shift 2;;   # per-run override; implies --active
    -r|--resolvers) RESOLVERS="$2"; shift 2;;
    --active) ACTIVE=1; shift;;
    --screenshots) SHOTS=1; shift;;
    --takeover) TAKEOVER=1; shift;;
    --check) CHECK=1; shift;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//' | head -30; exit 0;;
    -*) err "unknown flag $1"; exit 1;;
    *) ROOTS+=("$1"); shift;;
  esac
done

# ---------- tool inventory ----------
CORE=(subfinder dnsx httpx anew)
OPT=(amass github-subdomains katana gau waybackurls gowitness subzy nuclei puredns shuffledns dnsgen)
tool_report(){
  echo "Core (required):"
  for t in "${CORE[@]}"; do have "$t" && ok "$t" || err "$t  MISSING"; done
  echo "Optional (stages skipped if absent):"
  for t in "${OPT[@]}"; do have "$t" && ok "$t" || warn "$t  not installed"; done
  cat <<'EOF'

Install (most are Go tools):
  # ProjectDiscovery toolkit in one shot:
  go install github.com/projectdiscovery/pdtm/cmd/pdtm@latest && pdtm -ia
  # or individually:
  go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
  go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
  go install github.com/projectdiscovery/httpx/cmd/httpx@latest
  go install github.com/projectdiscovery/katana/cmd/katana@latest
  go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
  go install github.com/tomnomnom/anew@latest
  go install github.com/lc/gau/v2/cmd/gau@latest
  go install github.com/tomnomnom/waybackurls@latest
  go install github.com/gwen001/github-subdomains@latest
  go install github.com/sensepost/gowitness@latest
  go install github.com/PentestPad/subzy@latest            # (moved from LukaSikic/subzy)
  go install github.com/d3mondev/puredns/v2@latest         # active DNS brute
  go install github.com/owasp-amass/amass/v4/...@master    # or: snap install amass
  pipx install dnsgen                                       # permutations (Python, not Go)
  sudo apt install -y massdns   # REQUIRED for puredns/active mode  (or brew install massdns)
Configure subfinder API keys for far better passive coverage:
  ~/.config/subfinder/provider-config.yaml
EOF
}
if [ "$CHECK" = 1 ]; then tool_report; exit 0; fi

# ---------- gather roots ----------
if [ -n "$PROGRAM" ]; then
  sf="$TARGETS_DIR/$PROGRAM/scope.txt"
  [ -f "$sf" ] || { err "no scope.txt at $sf — run /scope first"; exit 1; }
  # pull wildcard roots from the RECON TARGETS block
  while read -r r; do ROOTS+=("$r"); done < <(
    awk '/^### RECON TARGETS/{f=1;next} /^### /{f=0} f' "$sf" \
      | grep -oE '\*\.[A-Za-z0-9.-]+' | sed 's/^\*\.//' | sort -u)
  SLUG="$PROGRAM"
fi
if [ -n "$ROOTS_FILE" ]; then
  [ -f "$ROOTS_FILE" ] || { err "no such file $ROOTS_FILE"; exit 1; }
  while read -r r; do [ -n "$r" ] && ROOTS+=("${r#\*.}"); done < "$ROOTS_FILE"
fi
[ "${#ROOTS[@]}" -gt 0 ] || { err "no roots given. pass a domain, -l file, or -p program"; exit 1; }
SLUG="${SLUG:-${ROOTS[0]}}"

# ---------- preflight ----------
for t in "${CORE[@]}"; do have "$t" || { err "missing core tool: $t (run --check)"; exit 1; }; done
[ -n "$UA" ] || warn "TESTING_USER_AGENT not set — many programs REQUIRE a specific UA. Set it in .env."
if [ "$ACTIVE" = 1 ]; then
  warn "ACTIVE mode: DNS brute/permutation sends traffic. Confirm the program allows active DNS."
  { [ -n "$WORDLIST" ] && [ -f "$WORDLIST" ]; } || { warn "no RECON_WORDLIST — disabling brute"; }
  have puredns || warn "puredns missing — disabling brute"
fi

OUT="$TARGETS_DIR/$SLUG/recon"; mkdir -p "$OUT"
STAMP="$(date +%Y%m%d-%H%M%S)"
UA_ARG=(); [ -n "$UA" ] && UA_ARG=(-H "User-Agent: $UA")
log "program: $SLUG   roots: ${ROOTS[*]}"
log "output:  $OUT   (active=$ACTIVE shots=$SHOTS takeover=$TAKEOVER rate=$RATE)"

# ---------- 1. passive subdomains ----------
log "stage 1 — passive subdomain enumeration"
PASS_NEW="$OUT/new_subs_$STAMP.txt"; : > "$PASS_NEW"
for dom in "${ROOTS[@]}"; do
  subfinder -d "$dom" -all -recursive -silent 2>/dev/null | anew "$OUT/subs.txt" >> "$PASS_NEW"
  if have amass; then amass enum -passive -d "$dom" 2>/dev/null | anew "$OUT/subs.txt" >> "$PASS_NEW"; fi
  if have github-subdomains && [ -n "${GITHUB_TOKEN:-}" ]; then
    github-subdomains -d "$dom" -t "$GITHUB_TOKEN" 2>/dev/null | anew "$OUT/subs.txt" >> "$PASS_NEW"; fi
  # crt.sh (no tool needed)
  curl -s "https://crt.sh/?q=%25.$dom&output=json" 2>/dev/null \
    | grep -oE '"name_value":"[^"]+"' | cut -d'"' -f4 | tr '\\n' '\n' \
    | sed 's/\*\.//g' | grep -E "\.$dom$" | anew "$OUT/subs.txt" >> "$PASS_NEW"
done
ok "subs.txt: $(wc -l < "$OUT/subs.txt" | tr -d ' ') total   ($(wc -l < "$PASS_NEW" | tr -d ' ') new this run)"

# ---------- 2. active DNS brute/permute (opt-in) ----------
if [ "$ACTIVE" = 1 ] && have puredns && [ -n "$WORDLIST" ] && [ -f "$WORDLIST" ]; then
  log "stage 2 — active DNS brute + permutation"
  RES_ARG=(); [ -n "$RESOLVERS" ] && [ -f "$RESOLVERS" ] && RES_ARG=(-r "$RESOLVERS")
  for dom in "${ROOTS[@]}"; do
    puredns bruteforce "$WORDLIST" "$dom" "${RES_ARG[@]}" -q 2>/dev/null | anew "$OUT/subs.txt" >> "$PASS_NEW"
  done
  if have dnsgen; then
    dnsgen "$OUT/subs.txt" 2>/dev/null | puredns resolve "${RES_ARG[@]}" -q 2>/dev/null \
      | anew "$OUT/subs.txt" >> "$PASS_NEW"
  fi
  ok "after active: $(wc -l < "$OUT/subs.txt" | tr -d ' ') total"
else
  [ "$ACTIVE" = 1 ] && warn "stage 2 skipped (missing puredns/wordlist)" || log "stage 2 — skipped (passive mode; use --active)"
fi

# ---------- 3. resolve ----------
log "stage 3 — resolve (dnsx)"
dnsx -l "$OUT/subs.txt" -a -resp -cname -silent -o "$OUT/resolved.txt" 2>/dev/null
dnsx -l "$OUT/subs.txt" -silent 2>/dev/null | sort -u > "$OUT/resolved_hosts.txt"
ok "resolved_hosts.txt: $(wc -l < "$OUT/resolved_hosts.txt" | tr -d ' ')"

# ---------- 4. probe HTTP ----------
log "stage 4 — HTTP probe (httpx)"
httpx -l "$OUT/resolved_hosts.txt" -sc -title -td -server -cdn -location \
      -p 80,443,8080,8443,8000,3000 -rl "$RATE" "${UA_ARG[@]}" -silent \
      -o "$OUT/live_detailed.txt" 2>/dev/null
grep -oE 'https?://[^ ]+' "$OUT/live_detailed.txt" 2>/dev/null | sort -u > "$OUT/live.txt"
ok "live.txt: $(wc -l < "$OUT/live.txt" | tr -d ' ') live hosts"

# ---------- 5. crawl + archived URLs ----------
log "stage 5 — URLs (katana + gau + waybackurls)"
if have katana; then
  katana -list "$OUT/live.txt" -jc -kf all -d 3 -rl "$RATE" "${UA_ARG[@]}" -silent 2>/dev/null \
    | anew "$OUT/urls.txt" >/dev/null; fi
for dom in "${ROOTS[@]}"; do
  have gau && gau --subs "$dom" 2>/dev/null | anew "$OUT/urls.txt" >/dev/null
  have waybackurls && waybackurls "$dom" 2>/dev/null | anew "$OUT/urls.txt" >/dev/null
done
[ -f "$OUT/urls.txt" ] && ok "urls.txt: $(wc -l < "$OUT/urls.txt" | tr -d ' ')" || warn "no url tools (katana/gau/waybackurls)"

# ---------- 6. subdomain takeover (opt-in, read-only fingerprint) ----------
if [ "$TAKEOVER" = 1 ]; then
  log "stage 6 — subdomain takeover fingerprint"
  if have subzy; then subzy run --targets "$OUT/resolved_hosts.txt" --hide_fails 2>/dev/null | tee "$OUT/takeover.txt"
  elif have nuclei; then nuclei -l "$OUT/live.txt" -t takeovers/ -silent 2>/dev/null | tee "$OUT/takeover.txt"
  else warn "no subzy/nuclei for takeover check"; fi
fi

# ---------- 7. screenshots (opt-in) ----------
if [ "$SHOTS" = 1 ]; then
  log "stage 7 — screenshots"
  if have gowitness; then gowitness scan file -f "$OUT/live.txt" --screenshot-path "$OUT/screenshots" 2>/dev/null && ok "screenshots → $OUT/screenshots"
  else warn "gowitness not installed"; fi
fi

# ---------- summary ----------
echo
ok "DONE — $SLUG @ $STAMP"
echo "  subdomains : $(wc -l < "$OUT/subs.txt" 2>/dev/null | tr -d ' ')  (+$(wc -l < "$PASS_NEW" 2>/dev/null | tr -d ' ') new)"
echo "  live hosts : $(wc -l < "$OUT/live.txt" 2>/dev/null | tr -d ' ')"
echo "  urls       : $(wc -l < "$OUT/urls.txt" 2>/dev/null | tr -d ' ')"
echo "  files      : $OUT/{subs,resolved,live_detailed,live,urls}.txt"
echo
echo "▶ next: run /triage on $OUT/live_detailed.txt, then /profile the hot hosts."
[ -s "$PASS_NEW" ] && echo "▶ $(wc -l < "$PASS_NEW" | tr -d ' ') NEW subdomains this run → $PASS_NEW (re-triage these)"
