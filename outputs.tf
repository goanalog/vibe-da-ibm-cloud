output "vibe_url" {
  description = "Public URL for your vibe app."
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/index.html"
}

output "vibe_bucket_url" {
  description = "Direct bucket URL."
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/"
}
