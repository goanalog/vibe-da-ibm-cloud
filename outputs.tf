output "vibe_bucket_url" {
  description = "Direct link to your COS bucket."
  value       = ibm_cos_bucket.bucket.bucket_name
}

output "vibe_url" {
  description = "Public access endpoint for your hosted vibe."
  value       = ibm_cos_bucket.bucket.s3_endpoint_public
}
