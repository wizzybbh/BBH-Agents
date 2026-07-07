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
returns only these). The list above **omits** every tool that sends traffic, so
the agent can read and *stage* but can never fire:

| Exposed (read / stage) | Withheld (never exposed) |
|---|---|
| `search_history`, `get_request` | `send_request` |
| `get_scope`, `check_scope` | `run_workflow` |
| `create_replay_session` (stage a request into a Replay tab) | `set_environment` |
| `create_finding`, `list_findings`, `list_projects`, `select_project`, `get_current_context`, `get_environment`, `intercept_status` | `intercept_pause` / `intercept_resume` |

Stronger than a permission-deny: the send tool isn't registered, so the agent
literally cannot send ([ADR 0002](adr/0002-human-stays-the-trigger.md)). The agent
**stages** cookie-swapped requests via `create_replay_session`; **you press Send**.

### Known drift bug (patched locally)

Out of the box, drift's `create_replay_session` and `send_request` fail against
current Caido — the mutation omits the required `kind: HTTP` and mis-shapes the
`requestSource` oneof (`Oneof input objects require exactly one field` /
missing-`kind` errors). Fix applied to
`~/tools/drift/packages/backend/assets/mcp-server.mjs` (and the installed copy):
send `kind: "HTTP"` and build `requestSource` as either `{ id }` **or**
`{ raw: { connectionInfo: {host,port,isTLS}, raw: <base64> } }`. The patched
`create_replay_session` also accepts `raw`+`host`, so the agent can stage a
**modified** (cookie-swapped) request without sending. Run `pnpm build` to bake it
in; worth filing upstream to six2dez.

## 4. Restart & use

Restart Claude Code so it loads the drift tools. Then `/hunt` builds each
cookie-swapped case, stages it into a Replay tab, and tells you which to fire.
You review, press **Send**, read the response. Same discipline as always
(one at a time, un-shared object for IDOR, halt on 3rd-party PII).
