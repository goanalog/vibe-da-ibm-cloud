output "vibe_bucket_url" {
  description = "Public URL to the index.html in your bucket."
  value       = "https://${ibm_cos_bucket.bucket.bucket_name}.${ibm_cos_bucket.bucket.s3_endpoint_public}/index.html"
}

output "vibe_url" {
  description = "Convenience alias to the same page."
  value       = "https://${ibm_cos_bucket.bucket.bucket_name}.${ibm_cos_bucket.bucket.s3_endpoint_public}/index.html"
}
