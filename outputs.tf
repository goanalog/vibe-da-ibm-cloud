output "vibe_bucket_name" {
  description = "The name of the created IBM Cloud Object Storage bucket."
  value       = try(ibm_cos_bucket.vibe_bucket.bucket_name, null)
}

output "vibe_bucket_crn" {
  description = "The CRN of the created IBM Cloud Object Storage bucket."
  value       = try(ibm_cos_bucket.vibe_bucket.crn, null)
}

output "vibe_bucket_website_endpoint" {
  description = "The public website endpoint for the COS bucket."
  # --- FIX: Use the actual website endpoint attribute ---
  value       = try(ibm_cos_bucket_website_configuration.vibe_bucket_website.website_endpoint, "Website endpoint not available")
}

output "push_cos_url" {
  description = "The URL endpoint for the 'push to COS' Code Engine function."
  value       = var.enable_code_engine && var.resource_group_id != null ? try(ibm_code_engine_function.push_to_cos[0].url, null) : null
}

output "push_project_url" {
  description = "The URL endpoint for the 'push to Project' Code Engine function."
  value       = var.enable_code_engine && var.resource_group_id != null ? try(ibm_code_engine_function.push_to_project[0].url, null) : null
}

output "primaryoutputlink" {
  description = "Primary access URL for the deployed website (used by IBM Cloud Projects)."
  # --- FIX: Use the actual website endpoint attribute ---
  value       = try(ibm_cos_bucket_website_configuration.vibe_bucket_website.website_endpoint, "Website endpoint not available")
}