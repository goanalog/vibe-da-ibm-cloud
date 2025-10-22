output "vibe_url" {
  description = "Public URL of your vibe-coded app."
  value       = "https://s3.${ibm_cos_bucket.bucket.region_location}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/index.html"
}

output "vibe_bucket_url" {
  description = "URL of your Cloud Object Storage bucket."
  value       = "https://s3.${ibm_cos_bucket.bucket.region_location}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/"
}
