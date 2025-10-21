output "vibe_bucket_url" {
  description = "Direct public URL of the hosted Vibe app."
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud"
}

output "vibe_url" {
  description = "Primary access URL for your deployed vibe code."
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud"
}
