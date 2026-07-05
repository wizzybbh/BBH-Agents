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
ALLOW="search_history,get_request,get_scope,check_scope,list_projects,select_project,get_current_context,clear_context_override,get_environment,intercept_status,list_findings,create_finding,create_replay_session"
claude mcp add drift -s user \
  -e CAIDO_URL=http://127.0.0.1:8080 \
  -e CAIDO_TOKEN="$CAIDO_API_TOKEN" \
  -e DRIFT_ALLOWED_TOOLS="$ALLOW" \
  -- node "$MJS"
claude mcp list | grep drift          # expect: ✔ Connected
```

## 3. The guardrail — allowlist excludes every transmit tool

`DRIFT_ALLOWED_TOOLS` is an **enforced allowlist** (drift's `getAvailableTools()`
returns only these). The list above **omits** the tools that send traffic, so the
agent can't call them — they aren't registered:

| Exposed (read / stage) | Withheld (transmit — human only) |
|---|---|
| `search_history`, `get_request` | **`send_request`** |
| `get_scope`, `check_scope` | **`run_workflow`** |
| `create_replay_session` (stage) | **`set_environment`** |
| `create_finding`, `list_findings` | **`intercept_pause` / `intercept_resume`** |
| `list_projects`, `select_project`, `get_current_context`, `get_environment`, `intercept_status` | |

Stronger than a Claude-Code permission-deny: the send tool doesn't exist for the
agent. (You can still add `"deny": ["mcp__drift__send_request"]` to `settings.json`
as belt-and-suspenders.)

**Verify staging once:** have the agent `create_replay_session` for one benign,
in-scope request and watch Caido — a Replay tab should appear with **nothing
sent**. If it fires, drop `create_replay_session` from the allowlist too and the
agent falls back to handing you the request text.

## 4. Restart & use

Restart Claude Code so it loads the drift tools. Then `/hunt` builds each
cookie-swapped case, stages it into a Replay tab, and tells you which to fire.
You review, press **Send**, read the response. Same discipline as always
(one at a time, un-shared object for IDOR, halt on 3rd-party PII).
