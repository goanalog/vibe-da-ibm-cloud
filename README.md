# 🌀 Vibe Deployable Architecture — Flat COS + Optional Functions

**Powered by IBM Cloud**

- Provisions **Cloud Object Storage (Lite)** and a public bucket (cross-region `us-geo`).
- Uploads a sample **index.html** so your URL works instantly.
- Exposes a primary output: **`vibe_url`**.
- (Optional) Deploys an **IBM Cloud Functions** web action for presigned uploads.
  - Disabled by default via `enable_functions = false` to ensure smooth validation.

## Deploy notes
- Works via IBM Cloud **Catalog** or **Projects**.
- To enable Functions:
  - Set variable `enable_functions=true` at deploy time.

Paste. Look. Share. **Vibe.**
