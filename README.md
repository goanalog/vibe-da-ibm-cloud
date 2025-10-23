# Vibe IDE — Cloud Manifestor

**Deploy → Click → Remix.** Provisions **IBM Cloud Object Storage (Lite)** + **IBM Cloud Functions (Lite)**,
injects endpoints into your app, and uploads it instantly — your vibe is live right after apply.

- Primary Output: **vibe_url** → click to open your live app.
- Safe by default: Lite plans only; uploads via Functions (no creds in browser).
- Public-read bucket for demo convenience (tighten later as needed).

## Created resources
- COS instance (Lite) + website bucket
- Functions (Lite):
  - `vibe-upload` — upload + versioning + rollback
  - `vibe-status` — readiness check
  - `vibe-project-update` — stages `project-update-request.json`

## Revert
Each deploy copies `index.html` → `index.prev.html`. Click **Revert 💫** in the app to restore.

## Pre-existing resources
- If `bucket_name` exists (and you own it), we reuse it.
- To avoid conflicts, delete old demo buckets or pick a new name.
- Destroy cleans up (`force_delete=true`).

## Attribution
Builds on static website DA concepts by **Arn Hyndman** (colleague).
