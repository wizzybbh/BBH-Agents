# GraphQL API Hacking

GraphQL endpoints concentrate BOLA/IDOR, info disclosure, auth bypass, and DoS —
often with weaker access control than REST because devs trust the schema. Read +
reason only.

## Find the endpoint

Common paths: `/graphql`, `/graphiql`, `/api/graphql`, `/v1/graphql`, `/query`,
`/gql`, `/graphql/console`, `/index.php?graphql`. Fingerprint: POST a `{__typename}`
query; GraphQL-specific errors ("Cannot query field…", "must provide query
string") confirm it. Look in JS bundles for `apollo`, `relay`, `urql`, gql tags.

## Introspection (map the schema)

Full schema dump:
```
{__schema{types{name fields{name args{name type{name}} type{name kind ofType{name}}}}}}
```
- If introspection is **disabled**, bypass attempts: append characters the GraphQL
  lexer ignores but a naive regex/WAF misses — `__schema` + space/newline/comma/
  tab, e.g. `{__schema\n{...}}`; try GET vs POST; try `application/x-www-form-
  urlencoded` vs JSON; try the `__type` probe.
- Still blocked → **field suggestion** ("Did you mean …") leaks field names; brute
  with **clairvoyance**/**graphql-cop**; or reconstruct from the client JS.

## Core attacks

- **BOLA/IDOR in nested & aliased queries** — request another user's object id
  deep in the graph; resolvers often skip authz on nested fields. Check each
  resolver independently.
- **Batching** — send many operations per HTTP request to defeat rate limiting /
  brute-force monitoring (credential stuffing, OTP/2FA brute, coupon abuse):
  - **Array batching**: `[{"query":"mutation{login(u,p1)}"},{"query":"…p2…"}]`.
  - **Alias batching**: `mutation{a:login(...) b:login(...) c:login(...)}` — one
    HTTP request, N attempts. Tools: **BatchQL** (array), **CrackQL** (alias).
- **Mutations** — enumerate `mutation` fields; test mass-assignment
  (`role`, `isAdmin`), unauthorized state change, price/quantity tampering.
- **Auth bypass** — mutations/queries reachable without/with low-priv token;
  classic case: password-reset / login mutation missing authz.
- **Info disclosure** — verbose errors, debug fields, `_debug`, deprecated fields,
  hidden types via introspection.
- **DoS** — deeply nested/circular queries (`{a{b{a{b…}}}}`), huge `first:`/
  `limit:` args, alias amplification, `@include`/`@skip` abuse. **Report as risk;
  don't actually take the service down** (bounty rules usually forbid DoS).
- **Injection** — args flow into SQL/NoSQL/OS if resolvers concatenate input;
  test SQLi/NoSQLi payloads in string args.
- **CSRF** — GraphQL over `GET` or `x-www-form-urlencoded` POST without CSRF token
  → GraphQL CSRF.

## Tooling

**InQL** (Burp ext + CLI, introspection → templates), **graphw00f** (engine
fingerprint), **graphql-cop** (security audit), **clairvoyance** (schema without
introspection), **BatchQL/CrackQL** (batching), **Altair/GraphiQL** (manual).

## Safe PoC

Use your own second account for BOLA; for batching brute, prove the mechanism
with a few attempts on your own account, not a real victim. Never DoS.

## References (current)

- PortSwigger Web Security Academy — GraphQL API vulnerabilities.
- OWASP GraphQL Cheat Sheet; HackTricks GraphQL.
- YesWeHack — Hacking GraphQL endpoints in bug bounty.

> Sources: [YesWeHack GraphQL](https://www.yeswehack.com/learn-bug-bounty/hacking-graphql-endpoints), [ASEC GraphQL Recon](https://www.asec.io/blog/graphql-hacking-101-reconnaissance), [OWASP GraphQL Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html), [PortSwigger GraphQL](https://portswigger.net/web-security/graphql)
