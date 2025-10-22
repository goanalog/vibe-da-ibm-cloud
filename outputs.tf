output "vibe_url" {
  description = "Public URL of your vibe-coded app."
  value       = "https://${ibm_cos_bucket.bucket.bucket_name}.s3.${ibm_cos_bucket.bucket.region_location}.cloud-object-storage.appdomain.cloud/index.html"
}

output "vibe_bucket_url" {
  description = "URL of your Cloud Object Storage bucket."
  value       = "https://${ibm_cos_bucket.bucket.bucket_name}.s3.${ibm_cos_bucket.bucket.region_location}.cloud-object-storage.appdomain.cloud"
}
