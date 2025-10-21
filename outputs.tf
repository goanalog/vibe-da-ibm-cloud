output "vibe_url" {
  description = "Behold the consecrated endpoint for direct vibe consumption."
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
}

output "vibe_bucket_url" {
  description = "Direct link to your sacred bucket."
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud"
}
