
# Vibe — Functional COS Uploader (Onboarding Test Build)

This package includes a **real Cloud Function** that uploads `index.html` to IBM Cloud Object Storage using **HMAC** and the **AWS SDK v3**.

## What gets created
- COS instance (Lite, global) + bucket (region: `us-south` by default)
- HMAC **resource key** (Writer) with `HMAC=true`
- Cloud Functions namespace, package, binding
- `push_to_cos` action, uploaded as a **ZIP (binary)** with `index.js` + `package.json`
- Web-enabled action URL (unauthenticated for demo; tighten in production)
- Terraform also uploads `index.html` initially via `ibm_cos_bucket_object`

## Notes on action packaging
- This repo ships a **zip artifact** at `functions/push_to_cos.zip` containing the code and `package.json`. Some environments require `node_modules` to be **pre-bundled** inside the ZIP. If invoke fails with a module error, run a local build:
  ```bash
  cd functions/push_to_cos_src
  npm install --omit=dev
  zip -r ../push_to_cos.zip .
  ```
  Then re-apply Terraform so the action contains dependencies.

## Try it
- Apply: `terraform init && terraform apply -auto-approve`
- Open output: `index_html_url`
- Invoke web action (no auth in this demo): `push_to_cos_web_action_url`
  - The action will upload whatever is in `html_input` (or bundled `index.html`) to the bucket as `index.html`.

## Security
- This demo leaves the action **web-exposed without auth** for ease of testing and onboarding checks. Use `web_secure=true` and IAM auth for production.
