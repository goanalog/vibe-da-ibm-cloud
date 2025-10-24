output "vibe_bucket_name" {
  description = "The name of the created IBM Cloud Object Storage bucket."
  value       = try(ibm_cos_bucket.vibe_bucket.bucket_name, null)
}

output "vibe_bucket_crn" {
  description = "The CRN of the created IBM Cloud Object Storage bucket."
  value       = try(ibm_cos_bucket.vibe_bucket.crn, null)
}

output "vibe_bucket_website_endpoint" {
  description = "The public website endpoint for the COS bucket. Note: Public access must be configured manually via IAM policy if needed."
  # --- Correctly reference the website config resource ---
  value       = try(ibm_cos_bucket_website_configuration.vibe_bucket_website.website_endpoint, "Website endpoint not available (Public access likely needed)")
}

output "push_cos_url" {
  description = "The URL endpoint for the 'push to COS' IBM Cloud Function action."
  value       = var.enable_functions && var.resource_group_id != null ? try(ibm_function_action.push_to_cos[0].target_endpoint_url, null) : null
}

output "push_project_url" {
  description = "The URL endpoint for the 'push to Project' IBM Cloud Function action."
  value       = var.enable_functions && var.resource_group_id != null ? try(ibm_function_action.push_to_project[0].target_endpoint_url, null) : null
}

output "primaryoutputlink" {
  description = "Primary access URL for the deployed website (used by IBM Cloud Projects). Note: Public access must be configured manually via IAM policy if needed."
  # --- Correctly reference the website config resource ---
  value       = try(ibm_cos_bucket_website_configuration.vibe_bucket_website.website_endpoint, "Website endpoint not available (Public access likely needed)")
}