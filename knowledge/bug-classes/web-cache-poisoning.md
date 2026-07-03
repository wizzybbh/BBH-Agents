# Web Cache Poisoning & Deception

Get a cache (CDN/reverse proxy) to store a malicious/private response and serve it
to other users. High impact (mass XSS, redirect, info disclosure) at scale. Hot
research area — PortSwigger 2024 "Gotta cache 'em all", 2025 "Web Cache
Entanglement". Read + reason; poison your own probe key, avoid harming real users.

## Core idea

Response is cached on a **cache key** (usually method + host + path + some params).
If input **outside** the key influences the response (unkeyed header/param/body),
you poison the cached copy for everyone hitting that key.

## Find unkeyed inputs

1. Add a cache-buster param (`?cb=random`) so you test your own key, not prod's.
2. Send candidate unkeyed headers and watch for reflection + `X-Cache: hit/miss`,
   `Age`, `CF-Cache-Status`, `X-Served-By` behavior:
   `X-Forwarded-Host`, `X-Forwarded-Scheme`, `X-Forwarded-Server`, `X-Host`,
   `X-Original-URL`, `X-Rewrite-URL`, `X-Forwarded-Prefix`, `Forwarded`, `Via`.
3. **Param cloaking / cache-key discrepancies**: cache and origin disagree on
   parsing — `?param;` , `?utm_x=1`, duplicate params, `;`-delimited params, path
   normalization (`/x/..%2f`, trailing dot, `//`), extension confusion
   (`/profile.css` served as HTML) → **cache deception** exposing private pages.
4. **Fat GET / body in cache key gaps (2025)**: Cloudflare & Rack::Cache forward
   GET-with-body without keying the body → poison via request body.

## Attacks

- **Poison → stored XSS/redirect**: unkeyed `X-Forwarded-Host` reflected into a
  `<script src>`/link/`<meta>` → point at attacker host; cache serves it to all.
- **Cache deception**: trick the cache into storing a victim's *authenticated*
  page under a public key (`/account/settings.css`) → read others' private data.
- **DoS via poisoning**: cache an error/oversized/redirect-loop response (report
  as risk; don't mass-poison prod).
- **Internal header injection**: poison with headers that change routing/auth.

## Method

Confirm the response is cacheable (`Cache-Control`, `Age`, repeated `X-Cache:
hit`), find an unkeyed input that changes the response, craft a harmful value,
then confirm a second clean request (same key, no header) gets the poisoned copy —
**using your cache-buster key so you don't hit real users**.

## Safe PoC

Poison a **unique buster key you own** and show a second request to that same key
returns your injected marker. Never poison a production key that real users share.

## Tools

**Param Miner** (Burp — unkeyed header/param discovery), Caido/Burp Repeater,
`X-Cache`/`Age`/`CF-Cache-Status` observation, PortSwigger cache labs.

## References (current)

- PortSwigger Research — *Practical Web Cache Poisoning*, *Web Cache Entanglement* (2025), *Gotta cache 'em all* (2024).
- Web Security Academy — Web cache poisoning & deception.

> Sources: [Gotta cache 'em all](https://portswigger.net/research/gotta-cache-em-all), [Web Cache Entanglement (2025)](https://portswigger.net/research/web-cache-entanglement), [Practical Web Cache Poisoning](https://portswigger.net/research/practical-web-cache-poisoning)
