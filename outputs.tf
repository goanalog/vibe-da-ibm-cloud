output "vibe_bucket" {
  description = "Bucket name hosting the site"
  value       = ibm_cos_bucket.bucket.bucket_name
}

output "vibe_bucket_website_endpoint" {
  description = "Public website endpoint"
  value       = ibm_cos_bucket_website_configuration.bucket_website.website_endpoint
}

# Handy S3-style endpoint you can use in clients if needed
output "s3_public_endpoint" {
  description = "S3 public endpoint for the region"
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud"
}

# Function URLs (may be null if functions disabled)
output "push_cos_url" {
  description = "Invoke URL for push_to_cos (HTTP)"
  value       = try(ibm_function_action.push_to_cos[0].target_endpoint_url, null)
}

output "push_project_url" {
  description = "Invoke URL for push_to_project (HTTP)"
  value       = try(ibm_function_action.push_to_project[0].target_endpoint_url, null)
}
