output "vibe_bucket_name" {
  value       = ibm_cos_bucket.vibe_bucket.bucket_name
  description = "The name of the created COS bucket."
}

# CHANGE THIS OUTPUT
output "vibe_url" {
  # This URL format works with the IAM Public Access policy
  value       = "http://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3-web.${ibm_cos_bucket.vibe_bucket.region_location}.cloud-object-storage.appdomain.cloud"
  description = "Public URL for your deployed Vibe app"
}