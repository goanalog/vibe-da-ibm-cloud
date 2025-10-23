
# Vibe Coder — Functions Live Edition (v1.1.1)

This Deployable Architecture provisions:
- COS Lite + Bucket
- Uploads `index.html`
- Cloud Functions namespace with two web actions:
  - `vibe/push_to_cos`      → writes `index.html` (drift-causing)
  - `vibe/push_to_project`  → writes `staged/index.html` (safe staging)

The bundled IDE calls these endpoints and shows muted‑neon success banners.
