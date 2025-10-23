output "vibe_bucket_name" {
  value       = ibm_cos_bucket.vibe_bucket.bucket_name
  description = "The name of the created COS bucket."
}

output "vibe_url" {
  description = "Public URL for your deployed Vibe app"
  value       = ibm_cos_bucket.vibe_bucket.website_endpoint
}
