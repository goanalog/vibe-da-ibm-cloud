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
  value       = try(ibm_cos_bucket_website_configuration.vibe_bucket_website.website_endpoint, "Website endpoint not available")
}

output "push_cos_url" {
  description = "The URL endpoint for the 'push to COS' Code Engine function."
  value       = var.enable_code_engine && local.has_required_ids ? one(ibm_code_engine_function.push_to_cos[*].url) : null
}

output "push_project_url" {
  description = "The URL endpoint for the 'push to Project' (staging) Code Engine function."
  value       = var.enable_code_engine && local.has_required_ids ? one(ibm_code_engine_function.push_to_project[*].url) : null
}

output "trigger_deploy_url" {
  description = "The URL endpoint for the 'trigger project deploy' Code Engine function."
  value       = var.enable_code_engine && local.has_required_ids ? one(ibm_code_engine_function.trigger_deploy[*].url) : null
}

# This is the primary output users will click
output "primaryoutputlink" {
  description = "Primary access URL for the deployed website (used by IBM Cloud Projects)."
  value       = try(ibm_cos_bucket_website_configuration.vibe_bucket_website.website_endpoint, "Website endpoint not available")
  sensitive   = false # Ensure this isn't accidentally marked sensitive
}