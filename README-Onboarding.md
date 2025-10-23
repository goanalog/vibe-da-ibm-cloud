
# IBM Cloud Catalog Onboarding — Notes
- Single `terraform { required_providers { ... } }` block (in `main.tf`).
- COS Lite (global) + us-south bucket.
- Cloud Functions inline Node.js (no deps), `web = true`, `resource_group_id` present.
- `index.html` uploaded by Terraform for instant success.
- Primary output link `vibe_url` for reviewer convenience.
