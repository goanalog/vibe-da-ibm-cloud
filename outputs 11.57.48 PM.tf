output "primaryoutputlink" {
  description = "Your live website URL (click to open)."
  value       = ibm_cos_bucket_website_configuration.vibe_bucket_website.website_endpoint
  sensitive   = false
}

output "vibe_bucket_name" {
  description = "Deployed bucket name."
  value       = ibm_cos_bucket.vibe_bucket.bucket_name
}

output "vibe_bucket_crn" {
  description = "Deployed bucket CRN."
  value       = ibm_cos_bucket.vibe_bucket.crn
}

output "vibe_bucket_website_endpoint" {
  description = "Public website endpoint."
  value       = ibm_cos_bucket_website_configuration.vibe_bucket_website.website_endpoint
}
