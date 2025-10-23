
# IBM Cloud Catalog Onboarding — Validation Guide

This Deployable Architecture package is pre-aligned to pass IBM Cloud Catalog Management validation.

## ✅ Quick checklist before uploading

1. **ZIP structure:** The root of the archive must contain:
   ```
   main.tf
   variables.tf
   outputs.tf (optional)
   manifest.yaml
   catalog.json
   README.md
   README-Onboarding.md
   index.html
   functions/
   ```

2. **Single provider declaration:**
   - Confirm there is only one `terraform { required_providers { ... } }` block in the entire package.
   - It is already defined inside `main.tf`.

3. **Lite plan usage:**
   - COS instance uses `plan = "lite"` and `location = "global"` — both valid for new accounts.

4. **Region:**
   - Defaults to `us-south` (safe for onboarding).

5. **HMAC key auto-generation:**
   - Terraform automatically creates and injects HMAC credentials into the Cloud Function, no user input required.

6. **Outputs:**
   - `index_html_url` — direct object link, should load on first apply.
   - `push_to_cos_web_action_url` — web action invocation URL (no auth; demo only).

7. **Manifest & Catalog metadata:**
   - `manifest.yaml` and `catalog.json` are minimal but sufficient to onboard in Catalog Management.

## 🧪 Validation testing steps

1. Navigate to **IBM Cloud → Catalog Management → Private Catalogs → Onboard Deployable Architecture**.
2. Upload the `vibe-coder-ready-full-clean.zip` archive.
3. Select your **account** and click **Validate**.
4. Confirm validation passes and proceed to **Add to Catalog**.
5. After onboarding, open the architecture in **IBM Cloud Projects**, click **Deploy**, and verify:
   - The COS instance and bucket are created.
   - The function is created successfully.
   - The website URL opens.

## 💡 Tips

- Schematics runs Terraform 1.1–1.3, so provider syntax must remain compatible.
- Avoid including local state or `.terraform` folders in the zip.
- Ensure filenames are lowercase and match `main.tf`, `variables.tf`, etc.
