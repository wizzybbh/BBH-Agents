# scripts/

Executable helpers the skills/subagents call. Run on the VPS where recon lives.

## `recon-pipeline.sh`

TBHM Day-1 enumeration for in-scope wildcard roots. **Passive by default**
(no brute traffic); active DNS behind `--active`. Uses `anew` so re-runs surface
only NEW subdomains — ideal for cron-based persistent recon. Authorized-testing
only; recon only (no vuln scanning / attack traffic — ADR 0002).

### Usage

```bash
./recon-pipeline.sh example.com                      # one root, passive
./recon-pipeline.sh -l roots.txt                     # many roots from a file
./recon-pipeline.sh -p acme                          # roots from ~/targets/acme/scope.txt
./recon-pipeline.sh example.com --active --screenshots --takeover
./recon-pipeline.sh --check                           # report installed vs missing tools
```

Flags: `--active` (DNS brute+permute — confirm the program allows it),
`--screenshots`, `--takeover`, `--check`, `-l <file>`, `-p <program>`.

Output → `${VPS_TARGETS_DIR:-~/targets}/<slug>/recon/`:
`subs.txt`, `resolved.txt`, `resolved_hosts.txt`, `live_detailed.txt`, `live.txt`,
`urls.txt`, `new_subs_<stamp>.txt` (+ `takeover.txt`, `screenshots/` if enabled).

Then: `/triage` on `live_detailed.txt` → `/profile` the hot hosts.

### Config (`.env` at repo root — see `.env.example`)

`VPS_TARGETS_DIR`, `TESTING_USER_AGENT` (many programs REQUIRE a specific UA),
`GITHUB_TOKEN`, `RECON_RATE`, `RECON_WORDLIST`, `RECON_RESOLVERS`.

### Tools

Run `./recon-pipeline.sh --check` to see what's installed. **Core (required):**
`subfinder dnsx httpx anew`. **Optional (stage skipped if absent):** `amass
github-subdomains katana gau waybackurls gowitness subzy nuclei puredns
shuffledns dnsgen` (+ `massdns` for puredns).

**Install everything (Go + ProjectDiscovery manager):**
```bash
# Go first (Ubuntu): sudo apt install -y golang-go   (or install latest from go.dev)
go install github.com/projectdiscovery/pdtm/cmd/pdtm@latest && pdtm -ia   # installs the PD suite
go install github.com/tomnomnom/anew@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/gwen001/github-subdomains@latest
go install github.com/sensepost/gowitness@latest
go install github.com/PentestPad/subzy@latest              # moved from LukaSikic/subzy
go install github.com/d3mondev/puredns/v2@latest
go install github.com/owasp-amass/amass/v4/...@master      # or: sudo snap install amass
pipx install dnsgen                                        # Python (permutations)
# massdns — REQUIRED for puredns/active mode; build from source (not in apt):
git clone https://github.com/blechschmidt/massdns && (cd massdns && make && sudo cp bin/massdns /usr/local/bin/)
```
Ensure `~/go/bin` is on your `PATH`. Add subfinder API keys
(`~/.config/subfinder/provider-config.yaml`) for much better passive coverage.

### Cron (persistent recon)

```cron
# weekly re-run; new subdomains land in new_subs_<stamp>.txt (and takeover.txt)
0 6 * * 1  cd ~/BBH-Agents/scripts && ./recon-pipeline.sh -p acme --takeover >> ~/targets/acme/recon/cron.log 2>&1
```
