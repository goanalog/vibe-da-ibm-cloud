# Auto-detect HTML vs base64 and handle safely, with fallback to bundled index.html
locals {
  source_raw       = trimspace(var.vibe_code_b64 != "" ? var.vibe_code_b64 : file("${path.module}/index.html"))
  looks_like_html  = can(regex("(?i)<html|<!doctype", local.source_raw))
  html_decoded     = local.looks_like_html ? local.source_raw : base64decode(local.source_raw)
}

# Example target object (keep your existing bucket resource wiring)
resource "ibm_cos_bucket_object" "vibe_code" {
  bucket   = ibm_cos_bucket.vibe_bucket.bucket_name
  key      = "index.html"
  content  = local.html_decoded
  etag     = md5(local.html_decoded)
}
