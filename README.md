# Vibe Coder — Live Functions Edition (v1.1.2)

Deploy a whole mood — instantly and repeatedly. This Deployable Architecture spins up:

- IBM Cloud Object Storage (Lite) with static website hosting
- Two IBM Cloud Functions to let your IDE push content:
  - **push_to_cos** (💥 drift): writes `index.html` live to the bucket
  - **push_to_project** (🧱 staged): writes `staged/index.html` for safe redeploy via Projects
- A **Vibe IDE** sample app that auto-injects the live Function URLs at deploy time

## How it works

- Terraform provisions COS + Functions and computes each action's `invoke_url`.
- The sample **/samples/index.html** is uploaded as a template with `templatefile()`.
- Placeholders `${PUSH_COS_URL}` and `${PUSH_PROJECT_URL}` are replaced with live URLs.
- Open the **Outputs** to find:
  - `vibe_url` (primary site)
  - `push_cos_url` and `push_project_url` (Function endpoints)

## Links (self-aware promo zone)

- Explore more **Deployable Architectures**: https://www.ibm.com/architectures/deployable-architectures  
- Meet **Project Bob**: https://www.ibm.com/products/bob

Made with ❤️ and AI assistance.
