output "vibe_bucket_name" {
  description = "Deployed COS bucket name."
  value       = ibm_cos_bucket.bucket.bucket_name
}

output "vibe_bucket_crn" {
  description = "COS bucket CRN."
  value       = ibm_cos_bucket.bucket.crn
}

output "vibe_bucket_website_endpoint" {
  description = "Public website endpoint for the bucket."
  value       = ibm_cos_bucket_website_configuration.bucket_website.website_endpoint
}

output "push_cos_url" {
  description = "Invoke URL for the push_to_cos Cloud Function (if enabled)."
  value       = var.enable_functions ? ibm_function_action.push_to_cos[0].target_endpoint_url : null
}

output "push_project_url" {
  description = "Invoke URL for the push_to_project Cloud Function (if enabled)."
  value       = var.enable_functions ? ibm_function_action.push_to_project[0].target_endpoint_url : null
}
