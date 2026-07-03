# Prototype Pollution (client- & server-side)

JS-specific. Polluting `Object.prototype` injects properties every object
inherits → DOM XSS (client), RCE / auth bypass / config override (server). Active
PortSwigger research area (2024–25). Read + reason only.

## Client-side (CSPP → DOM XSS)

- **Sources**: `location.search`/`hash` parsed into objects, `JSON.parse` of user
  data, jQuery `$.extend(true, …)`, `Object.assign` deep-merge libs, query-string
  parsers (`qs`, `deparam`).
- **Probe**: `?__proto__[test]=polluted` then in console check
  `Object.prototype.test === 'polluted'`. Also `?constructor[prototype][test]=x`.
- **Gadgets → XSS**: pollute a property a sink later reads unsanitized —
  `?__proto__[src]=data:,alert(1)`, `__proto__[innerHTML]`,
  `__proto__[transport_url]`, framework config props (`sanitizer`, `srcdoc`,
  script `src`). Chain pollution → gadget → execution.
- **DOM Invader** (Burp) automates source→gadget discovery.

## Server-side (SSPP → RCE / bypass)

- Reaches `Object.prototype` via JSON body deep-merge (`lodash.merge`,
  `_.defaultsDeep`, `Object.assign` recursion), config loaders, `req.query`
  parsers.
- **Black-box detection without DoS** (PortSwigger technique): send
  `{"__proto__":{"json spaces":10}}` (Express) and watch response JSON whitespace
  change; or pollute a header-reflected/parsing property and observe a benign
  behavior change. Avoid the crash-y `status`/`content-type` probes that DoS.
- **Impact gadgets**: override `status`/`shell`/`NODE_OPTIONS`/`execArgv` →
  RCE via child_process spawn; pollute auth/ACL flags → privilege bypass; pollute
  template options → SSTI/XSS.

## Payload shapes to try

```
{"__proto__":{"polluted":"x"}}
{"constructor":{"prototype":{"polluted":"x"}}}
?__proto__[polluted]=x        &constructor[prototype][polluted]=x
__proto__.polluted=x  (form-encoded)
```
Blocked `__proto__`? try `constructor.prototype`, unicode/dup keys, array wrappers.

## Safe PoC

Client: `Object.prototype.<x>` set + a benign gadget firing `alert(document.domain)`.
Server: a **non-destructive** observable change (JSON spacing, a reflected flag) —
do not trigger the crash/DoS probes or run real RCE beyond `id`-level proof.

## Tools

**DOM Invader** (Burp), PortSwigger **server-side prototype pollution scanner**
Burp ext, **ppmap**, **pputil**, ppfuzz. GHunter research for runtime gadgets.

## References (current)

- PortSwigger Research — *Server-side prototype pollution: black-box detection without DoS*; client-side PP labs.
- Web Security Academy — Prototype pollution.

> Sources: [PortSwigger SSPP research](https://portswigger.net/research/server-side-prototype-pollution), [Web Security Academy SSPP](https://portswigger.net/web-security/prototype-pollution/server-side), [GHunter (arXiv)](https://arxiv.org/pdf/2407.10812)
