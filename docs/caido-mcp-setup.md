# Caido MCP setup — "agent stages, you send"

Optional. Wires the **drift** Caido MCP into Claude Code so the agent can **read**
your captured traffic and **stage** ready-to-fire requests into Caido Replay —
while **you** press Send. Preserves [ADR 0002](adr/0002-human-stays-the-trigger.md):
the transmit tools are never exposed to the agent.

Runs on the **laptop** (where Caido is), for `/profile` and `/hunt`.

## 1. Build & install the plugin

```bash
git clone https://github.com/six2dez/drift ~/tools/drift && cd ~/tools/drift
corepack enable && pnpm install && pnpm build
```
The artifact is **`dist/plugin_package.zip`** (not `drift.zip`, despite the README).
In Caido: **Plugins → Install Package → select `~/tools/drift/dist/plugin_package.zip`**.
Then open drift's page → **Start MCP server**.

## 2. Register with Claude Code (manual — auto-register often misses)

Drift's auto-registration frequently doesn't reach Claude Code (`claude mcp list`
won't show it). Register it yourself. Find the server drift extracted:
```bash
find ~/Library/Application\ Support/io.caido.Caido/plugins -name mcp-server.mjs
```
Then add it, pulling the Caido token from `.env` (never type it inline). **Note
`CAIDO_URL` is the base — drift appends `/graphql` itself:**
```bash
cd ~/Documents/"BB AI Agents" && set -a && . ./.env && set +a
MJS="<path from the find above>"
ALLOW="search_history,get_request,get_scope,check_scope,list_projects,select_project,get_current_context,clear_context_override,get_environment,intercept_status,list_findings,create_finding,create_replay_session,send_request"
claude mcp add drift -s user \
  -e CAIDO_URL=http://127.0.0.1:8080 \
  -e CAIDO_TOKEN="$CAIDO_API_TOKEN" \
  -e DRIFT_ALLOWED_TOOLS="$ALLOW" \
  -- node "$MJS"
claude mcp list | grep drift          # expect: ✔ Connected
```

## 3. The guardrail — allowlist + GET-only confirmation ([ADR 0003](adr/0003-get-only-sends-under-confirmation.md))

`DRIFT_ALLOWED_TOOLS` is an **enforced allowlist** (drift's `getAvailableTools()`
returns only these). `send_request` is exposed **for GET-only reads under
confirmation**; the other transmit tools are withheld entirely:

| Exposed (read / stage) | Exposed but confirmation-gated | Withheld (never exposed) |
|---|---|---|
| `search_history`, `get_request` | **`send_request`** — GET only, human-approved | `run_workflow` |
| `get_scope`, `check_scope`, `create_replay_session` | | `set_environment` |
| `create_finding`, `list_findings`, `list_projects`, `select_project`, `get_current_context`, `get_environment`, `intercept_status` | | `intercept_pause` / `intercept_resume` |

**Force the confirmation prompt** — add to the laptop `~/.claude/settings.json`
so `send_request` always asks (and the transmit tools are denied as backup):
```jsonc
"permissions": {
  "ask":  ["mcp__drift__send_request"],
  "deny": ["mcp__drift__run_workflow", "mcp__drift__set_environment",
           "mcp__drift__intercept_pause", "mcp__drift__intercept_resume"]
}
```
Run the hunt session in a **prompting** mode (`claude --permission-mode default`),
not `auto`/`bypass`, or the prompt can be skipped.

**Method gate is human.** drift doesn't filter by HTTP method — the agent's
charter restricts it to GET, but *you* must verify the method at the confirmation
prompt and **decline anything that isn't a GET** (writes are fired by hand).

**Verify once:** have the agent `send_request` a benign in-scope GET. You MUST see
a confirm prompt before anything goes out. If it fires with no prompt → you're in
auto mode; stop and fix it before any real testing.

## 4. Restart & use

Restart Claude Code so it loads the drift tools. Then `/hunt` builds each
cookie-swapped case, stages it into a Replay tab, and tells you which to fire.
You review, press **Send**, read the response. Same discipline as always
(one at a time, un-shared object for IDOR, halt on 3rd-party PII).
