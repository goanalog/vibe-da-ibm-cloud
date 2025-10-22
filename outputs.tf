output "vibe_url" {
  description = "Public URL for your deployed vibe-coded app — your key output."
  value       = "https://s3.${ibm_cos_bucket.bucket.region_location}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/index.html"
}

output "vibe_bucket_url" {
  description = "Direct Cloud Object Storage bucket URL (advanced access)."
  value       = "https://s3.${ibm_cos_bucket.bucket.region_location}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/"
}