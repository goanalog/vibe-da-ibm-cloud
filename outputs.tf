output "vibe_bucket_name" {
  value       = ibm_cos_bucket.vibe_bucket.bucket_name
  description = "The name of the created COS bucket."
}

# CHANGE THIS OUTPUT back to the S3 API endpoint
output "vibe_url" {
  value       = "https://s3.${ibm_cos_bucket.vibe_bucket.region_location}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.vibe_bucket.bucket_name}/index.html"
  description = "Public URL for your deployed Vibe app"
}