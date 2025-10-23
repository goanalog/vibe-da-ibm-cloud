# ---------------------------------------------------------
# Max Vibe Edition Outputs — safe for IBM Cloud validation
# ---------------------------------------------------------

output "vibe_bucket_name" {
  description = "Name of your Vibe COS bucket."
  value       = try(ibm_cos_bucket.bucket.bucket_name, null)
}

output "vibe_bucket_crn" {
  description = "CRN of your Vibe COS bucket."
  value       = try(ibm_cos_bucket.bucket.crn, null)
}

output "vibe_bucket_website_endpoint" {
  description = "Public website endpoint of your Vibe bucket."
  value       = try(ibm_cos_bucket_website_configuration.bucket_website.website_endpoint, null)
}

output "push_cos_url" {
  description = "Cloud Function endpoint for pushing updates to COS."
  value       = var.enable_functions ? try(ibm_function_action.push_to_cos[0].target_endpoint_url, null) : null
}

output "push_project_url" {
  description = "Cloud Function endpoint for pushing updates to IBM Cloud Projects."
  value       = var.enable_functions ? try(ibm_function_action.push_to_project[0].target_endpoint_url, null) : null
}

# Primary output for IBM Cloud Projects “Launch App” link
output "primaryoutputlink" {
  description = "Primary vibe app website URL for IBM Cloud Projects UI."
  value       = try(ibm_cos_bucket_website_configuration.bucket_website.website_endpoint, null)
}
