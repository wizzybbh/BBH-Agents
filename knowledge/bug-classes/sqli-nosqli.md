# SQLi & NoSQLi — Injection

Rarer on modern ORM stacks but still high-severity and present in raw-query
corners, legacy endpoints, search/filter/sort params, and reporting. Read +
reason only; prove with safe boolean/time payloads, never dump real PII or write.

## Where it lives (bias by stack — see framework matrix)

Raw queries: `.raw()`/`.extra()` (Django), `DB::raw`/`whereRaw` (Laravel),
string-concatenated queries (Node/Express, PHP legacy), stored procs, `ORDER BY`/
`GROUP BY` (column context — params can't be bound), `LIMIT`/`OFFSET`, dynamic
`IN (...)`, search filters, export/report endpoints, GraphQL resolvers that
concatenate args.

## Detection (non-destructive)

1. **Error-based**: `'`, `"`, `)`, `';`, backtick → SQL error / 500 / behavior change.
2. **Boolean**: `... AND 1=1` vs `... AND 1=2` → different responses = injectable.
3. **Time-based (blind)**: `'|| pg_sleep(5)--`, `'; WAITFOR DELAY '0:0:5'--`,
   `' OR SLEEP(5)--`, `'||dbms_pipe.receive_message(('a'),5)||'` (Oracle). Confirm
   with varying delays to rule out noise.
4. **OOB**: DNS exfil via `LOAD_FILE`/`xp_dirtree`/`UTL_HTTP` to interactsh (blind).
5. **`ORDER BY n`** increment to find column count; `UNION SELECT NULL,NULL...`.

## Bypasses

Inline comments `/**/`, case toggling, `UNION/**/SELECT`, `%00`, double-URL-encode,
`OR 1=1-- -` spacing, `%09`/`%0a` whitespace, `information_schema` alternatives,
WAF-specific keyword splitting, JSON/second-order (input stored then used in query
later). Hex/char encoding for filtered quotes.

## NoSQLi (Mongo etc.)

- **Auth bypass / operator injection**: JSON body `{"user":"admin","pass":{"$ne":null}}`,
  `{"$gt":""}`, `{"$regex":"^a"}`; in query string `user[$ne]=x&pass[$ne]=x`.
- **Boolean/time blind**: `$where` JS injection `'||sleep(5000)||'`, regex oracle
  to extract values char-by-char.
- Watch GraphQL/JSON APIs that pass objects straight into Mongo.

## Escalation

Data exfil (prove with `version()`/`current_user`, **not** real records),
auth bypass, file read/write (`INTO OUTFILE`, `LOAD_FILE`), RCE (`xp_cmdshell`,
stacked queries). For bounty: prove injection + reachable impact; do not exfiltrate
customer data or write to the DB.

## Tools

**sqlmap** (`--batch --risk 2 --level 3`, `--technique`, `--dbms`; use for
confirmation, respect rate limits & scope), **ghauri**, **NoSQLMap**, Caido/Burp
Repeater for manual boolean/time proofs, interactsh for OOB.

## Safe PoC

Boolean pair (`1=1` vs `1=2`) + a controlled time delay, or `@@version`/`user()`.
Screenshot the differential. Never `DROP`, `UPDATE`, `DELETE`, or dump PII.

## References (current)

- PortSwigger Web Security Academy — SQL injection (+ blind, OOB) & NoSQL injection.
- PayloadsAllTheThings — SQL / NoSQL injection.
