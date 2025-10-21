output "vibe_bucket_url" {
  description = "S3 public endpoint for the bucket."
  value       = "https://${ibm_cos_bucket.bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud"
}

output "vibe_url" {
  description = "Direct URL to index.html."
  value       = "https://${ibm_cos_bucket.bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
}
