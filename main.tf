locals {
  html_decoded = (
    can(base64decode(var.vibe_code_b64))
    ? base64decode(var.vibe_code_b64)
    : var.vibe_code_b64 != "" ? var.vibe_code_b64 : file("${path.module}/index.html")
  )
}

resource "ibm_cos_bucket_object" "vibe_code" {
  bucket   = ibm_cos_bucket.vibe_bucket.bucket_name
  key      = "index.html"
  content  = local.html_decoded
  etag     = md5(local.html_decoded)
}
