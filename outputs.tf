# Primary launch link for IBM Cloud Projects & Catalog
output "vibe_url" {
  description = "Primary Vibe site URL (static website endpoint)."
  value       = "https://${ibm_cos_bucket.bucket.bucket_name}.s3-web.${ibm_cos_bucket.bucket.region_location}.cloud-object-storage.appdomain.cloud"
}

# Convenience: same endpoint as above (kept for backward-compat)
output "vibe_bucket_url" {
  description = "Alias for the static website URL."
  value       = "https://${ibm_cos_bucket.bucket.bucket_name}.s3-web.${ibm_cos_bucket.bucket.region_location}.cloud-object-storage.appdomain.cloud"
}

# Functions (useful for testing / automation)
output "push_cos_url" {
  description = "IBM Cloud Function URL for Push-to-COS (POST)."
  value       = local.push_cos_url
}

output "push_project_url" {
  description = "IBM Cloud Function URL for Push-to-Project (POST)."
  value       = local.push_project_url
}
