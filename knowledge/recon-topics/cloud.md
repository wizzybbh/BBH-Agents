# Cloud Asset Recon

Find the org's cloud storage and services — buckets, blobs, and misconfigured
cloud surfaces are frequent, high-value finds. Only test assets in scope.

## Find bucket / storage names

- From JS/HTML/DNS/CNAMEs: `s3.amazonaws.com`, `<name>.s3.<region>.amazonaws.com`,
  `storage.googleapis.com/<bucket>`, `<acct>.blob.core.windows.net`,
  `<proj>.firebaseio.com`, `<proj>.appspot.com`.
- Permute org/brand names: `target-assets`, `target-prod`, `target-backups`,
  `target-dev`, `target-static`, `target-uploads` (+ common suffixes).
- Tools: **cloud_enum** (AWS/GCP/Azure at once), **s3scanner**, **GCPBucketBrute**,
  **massdns** on cloud CNAMEs.

## Test buckets (non-destructive)

```
aws s3 ls s3://bucket --no-sign-request                 # list (public read)
aws s3 cp s3://bucket/file . --no-sign-request           # read
# write test (careful — only prove, never deface):
echo poc > poc.txt; aws s3 cp poc.txt s3://bucket/ --no-sign-request
```
- **Public read** → data exposure (severity by contents). **Public write** →
  supply-chain (overwrite served JS) — prove with a **benign** token file, then
  remove; do not deface or replace real assets.
- GCS: `gsutil ls gs://bucket`; Azure: enumerate container + blob list; Firebase:
  `https://<proj>.firebaseio.com/.json` (open DB read).

## Cloud IP ranges & services

- ASN/CIDR (see asn-acquisitions.md) → but **cloud IPs are shared** — a host on AWS
  space is only in scope if it's the target's app (confirm by cert/host, not IP owner).
- Look for exposed: Elasticsearch/Kibana (`:9200/:5601`), Docker/k8s
  (`:2375/:6443/:10250`), Redis (`:6379`), Jenkins, Grafana, MinIO consoles.
- **SSRF → cloud metadata** is the exploitation side — see `bug-classes/ssrf.md`.

## Subdomain takeover (cloud-dangling)

Dangling CNAMEs to S3/CloudFront/Azure/Heroku/GitHub Pages → takeover (see
`bug-classes/subdomain-takeover.md`). Cloud infra churn is the #1 source.

## Output

`buckets.txt` (state: read/write/private), exposed-service list → validate →
`/report`; takeover candidates → subdomain-takeover check.

## Tools

cloud_enum, s3scanner, GCPBucketBrute, awscli (`--no-sign-request`), gsutil,
nuclei (`exposures/`, `misconfiguration/`), subzy (takeover).

## Guardrail

Prove exposure minimally; never exfiltrate customer data or deface. Respect scope —
cloud IP ownership ≠ authorization.
