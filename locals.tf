locals {
  # If user provides HTML, use it; otherwise fall back to the sample
  vibe_code_raw = var.vibe_code != "" ? var.vibe_code : file("${path.module}/index.html")

  # Safely encode it for upload to COS
  vibe_code_b64 = base64encode(local.vibe_code_raw)

  # Derived URLs for reuse
  vibe_url = "https://${ibm_cos_bucket.vibe.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
}
