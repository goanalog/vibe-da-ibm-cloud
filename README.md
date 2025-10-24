# 🌀 Vibe Landing Zone — Perfect Tens Edition

Deploy a live, remixable sample site on **IBM Cloud Object Storage (Lite)**.  
Based on the [Static Website Deployable Architecture](https://cloud.ibm.com/catalog/architecture/static-website-cffed3d6-f05c-408d-941d-f679ae4e2451-global).

![Diagram](https://raw.githubusercontent.com/goanalog/vibe-da-ibm-cloud/main/diagram.svg)

**Paste. Look. Share. Vibe.**  
The Free Vibe Bucket — a zero‑cost cosmic cache where anyone can toss raw code into the cloud and watch it beam across the internet.

---

## How it works
- Provisions **IBM Cloud Object Storage (Lite)**.
- Creates a unique bucket and configures **static website hosting**.
- Uploads `sample-app/index.html` and `sample-app/404.html`.
- Surfaces a **primaryoutputlink** with your live URL in Projects.

## Inputs
- `region` (default: `us-south`)
- `bucket_prefix` (default: `vibe-bucket`)
- `website_index` (default: `index.html`)
- `website_error` (default: `404.html`)

## Outputs
- `primaryoutputlink` *(primary)* — live website URL
- `vibe_bucket_name` — bucket name
- `vibe_bucket_crn` — bucket CRN
- `vibe_bucket_website_endpoint` — website endpoint

## Extend the vibe
Want to push new HTML?  
1. Edit `sample-app/index.html` in your Project repo.  
2. Click **Redeploy** in IBM Cloud Projects.  
3. Your new vibe replaces the live site instantly.

## Cleanup
Use **Destroy Resources** in Projects or Schematics to clean up.  
COS Lite is free, so experimenting costs $0.

---

> Made with ✨ AI assistance and IBM Cloud Deployable Architectures.
