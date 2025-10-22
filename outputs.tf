# 🌐 Primary Output Link — appears first in IBM Cloud Projects UI
# Users can click this to access their live deployed app instantly.
output "vibe_url" {
  description = "Primary output link. The public URL of your live deployed vibe-coded app."
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
  sensitive   = false
}

# Secondary output for advanced users or programmatic access.
output "vibe_bucket_url" {
  description = "Direct Cloud Object Storage bucket URL (advanced access)."
  value       = "https://{ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud"
}