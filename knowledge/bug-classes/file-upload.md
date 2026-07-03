# File Upload Vulnerabilities

Upload features are rich: RCE (web shell), stored XSS (SVG/HTML), SSRF (SVG/XXE),
path traversal, and DoS. Read + reason; upload only benign proofs.

## Attack surface

Avatar/profile pics, document/attachment upload, import (CSV/XML/JSON), resume,
logo, ticket attachments, `POST` multipart, pre-signed S3 URLs, chunked uploads.

## Test progression

1. **Extension/content-type checks** — upload `.php`/`.jsp`/`.aspx`/`.phtml`;
   bypass with:
   - double ext `shell.php.jpg`, `shell.jpg.php`, trailing dot/space `shell.php.`,
     `shell.php%00.jpg` (null), case `.pHp`, alt exts `.phtml .php5 .php7 .phar
     .pht .asp .aspx .cshtml .jsp .jspx`.
   - `Content-Type: image/jpeg` spoof on a script body.
   - magic-byte prefix: `GIF89a;<?php system($_GET['c']);?>`.
   - polyglots (valid image + code).
2. **Where does it land?** — find the stored URL/path; is it web-served and
   executed? (`/uploads/shell.php`). Content-discovery the upload dir.
3. **SVG/HTML → stored XSS** — upload `.svg` with `<script>`/`onload=` or `.html`;
   if served inline (not `Content-Disposition: attachment`) → XSS in target origin.
4. **SVG/XML → XXE/SSRF** — SVG/`.docx`/`.xlsx`/XML with external entity →
   file read / SSRF (see xxe & ssrf playbooks).
5. **Path traversal in filename** — `../../../../var/www/html/shell.php`,
   `..%2f`, override existing files, zip-slip on archive import.
6. **Image parser exploits** — ImageMagick/`convert` (ImageTragick class),
   Ghostscript, ExifTool CVEs → RCE via crafted image; fingerprint the processor.
7. **Client-side-only validation** — intercept and change the file after the JS check.
8. **Pre-signed URL / S3** — tamper `key`/`Content-Type`, upload outside intended
   prefix, public-read ACL, overwrite others' objects (→ IDOR).
9. **DoS** — decompression bombs, pixel-flood images, huge/looping archives (report, don't detonate prod).

## Escalation

Web shell → RCE; stored SVG/HTML XSS in admin view → ATO; overwrite → integrity;
XXE → file read/SSRF. Chain upload-path + content-discovery to reach execution.

## Safe PoC

Benign marker: a web shell that only echoes a unique token (`<?php echo
'poc-<handle>'; ?>`) or an SVG that `alert(document.domain)`s. Don't run real
commands beyond `id`; remove the file after if the program requests.

## Tools

Caido/Burp (intercept + modify multipart), **Upload_Bypass**, exiftool, nuclei
upload templates (leads), content-discovery (ffuf) for the storage dir.

## References (current)

- PortSwigger Web Security Academy — File upload vulnerabilities.
- PayloadsAllTheThings — Upload Insecure Files.
