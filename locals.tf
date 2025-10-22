locals {
  # Use user-provided code, or fall back to sample
  vibe_code_raw = var.vibe_code != "" ? var.vibe_code : file("${path.module}/index.html")

  # Always encode safely before Terraform or provider processing
  vibe_code_b64 = base64encode(local.vibe_code_raw)
}
