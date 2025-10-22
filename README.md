# Vibe Landing Zone — Max Vibe (Lite, Secure, Auto-Seed, Auto-Vars)

This Deployable Architecture provisions:
- IBM Cloud Object Storage (COS) **Lite** instance + unique bucket (**public read**, not public write)
- Auto-generated **COS HMAC** credentials (no manual inputs)
- IBM Cloud Function web action `get-presigned-url` (Node.js 18) in **us-south** that issues short-lived presigned PUT URLs
- A vibey **CodeMirror IDE** `index.html` with the function URL **pre-embedded**
- **Auto-seed**: `index.html` is uploaded to your bucket during `terraform apply`, so the app is live immediately

## 💸 Zero-cost (Lite)
All resources are **Lite tier**. Lite plans cannot generate charges — services simply stop when free quotas are reached.

## Variables
- `region` (default `us-south`)
- `bucket_prefix` (default `vibe-bucket`)

## Outputs
- `vibe_url` (primary) — open this to use the IDE immediately after apply
- `vibe_bucket_url` — base bucket endpoint
- `bucket_name` — unique name
- `upload_endpoint` — pre-embedded guest/default web action URL
- `hmac_access_key_id`, `hmac_secret_access_key` — generated credentials used by the function (shown for reference; secret is marked sensitive)

## 🪄 Auto-Seeded + Auto-Vars
- HMAC credentials are created automatically and passed into the Function.
- The exact guest/default web action URL is pre-baked into your deployed `index.html`, so **Manifest ✨** works instantly, no prompts.
- On `terraform apply`, Terraform uploads the provided `index.html` to the bucket. Your live IDE is ready at `vibe_url` with no manual steps.

Security: writes only via the function (signed URLs). Bucket is **not** public-write.
