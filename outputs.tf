# Primary launch link for IBM Cloud Projects & Catalog
output "vibe_url" {
  description = "Primary Vibe site URL (static website endpoint)."
  value       = ibm_cos_bucket.bucket.website_url
}

# Convenience: same endpoint as above (kept for backward-compat)
output "vibe_bucket_url" {
  description = "Alias for the static website URL."
  value       = ibm_cos_bucket.bucket.website_url
}

# Functions (useful for testing / automation)
output "push_cos_url" {
  description = "IBM Cloud Function URL for Push-to-COS (POST)."
  value       = ibm_function_action.push_to_cos.invoke_url
}

output "push_project_url" {
  description = "IBM Cloud Function URL for Push-to-Project (POST)."
  value       = ibm_function_action.push_to_project.invoke_url
}
