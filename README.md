# Vibe IDE — Static Web + Cloud Functions ✨

**Deployable Architecture** for IBM Cloud that ships a single-file web IDE with live deploys to Cloud Object Storage and Cloud Functions for uploads, status, project updates, and anonymous analytics.

## What you get
- **COS (Lite)** public bucket for hosting your site + analytics JSON
- **Functions (Lite)** for:
  - `vibe_index` (serves the IDE immediately as the primary link)
  - `vibe_manifest` (uploads `index.html` to COS, public-read)
  - `vibe_status` (pings a URL to confirm readiness)
  - `vibe_update_project` (stages a config update request file in the bucket)
  - `vibe_analytics` (anonymous event pings -> COS `/analytics/`)
- **Primary output**: `vibe_url` (click to open IDE post-deploy)

## How to use
1. Deploy from IBM Cloud **Catalog** or **Project**.
2. Click the **vibe_url** output → you’re in the IDE.
3. Edit code → click **Manifest ✨** → your public page opens.
4. Click **Pro Update 🌈** to stage a Project config update request JSON in your bucket.

## Public access
Objects uploaded by `vibe_manifest` are written with `public-read` ACL so anyone with the URL can view (`https://<bucket>.<region>.cloud-object-storage.appdomain.cloud/index.html`).

## Pre-existing resources
- If a bucket with the same name exists, we suffix a random string unless you provide `bucket_name`.
- Re-deploys won’t delete existing content. Use COS UI to clean up if needed.

## IBM Cloud Private Catalogs
This DA is designed to shine inside **Private Catalogs** — IBM Cloud’s built-in platform engineering capability.
- Publish once; your teams deploy with a click.
- Keep versioned, auditable blueprints.
- Integrates natively with Projects.

## Attribution
This work builds upon ideas pioneered by **Arn Hyndman** on a *Static Website Deployable Architecture* within IBM Cloud. 🙌

## License
Apache-2.0