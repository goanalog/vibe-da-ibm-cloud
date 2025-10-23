output "vibe_url" {
  value       = ibm_cos_bucket.bucket.website_url
  description = "Primary Vibe site URL (promoted output)"
}

output "vibe_bucket_url" {
  value = ibm_cos_bucket.bucket.website_url
}

output "push_cos_url" {
  value       = ibm_function_action.push_to_cos.invoke_url
  description = "Live IBM Cloud Function URL for Push-to-COS"
}

output "push_project_url" {
  value       = ibm_function_action.push_to_project.invoke_url
  description = "Live IBM Cloud Function URL for Push-to-Project"
}
