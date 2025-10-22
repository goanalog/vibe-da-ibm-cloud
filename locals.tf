locals {
  # If user provides HTML (and it's not the default placeholder), use it;
  # otherwise fall back to the sample index.html file.
  vibe_code_raw = var.vibe_code != "" && var.vibe_code != "Paste your HTML code here" ?
  var.vibe_code : file("${path.module}/index.html")

  # Safely encode it for upload to COS
  vibe_code_encoded = base64encode(local.vibe_code_raw)

  # Derived URL, fixed to use var.region and correct bucket resource name
  vibe_url = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.vibe_bucket.bucket_name}/index.html"
}