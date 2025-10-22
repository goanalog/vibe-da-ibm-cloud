# 🌐 Primary Output Link — appears first in IBM Cloud Projects UI
# Users can click this to access their live deployed app instantly.
output "vibe_url" {
  description = "Primary output link. The public URL of your live deployed vibe-coded app."
  value       = ibm_cos_bucket_object.website.endpoint
  sensitive   = false
}

# Secondary output for advanced users or programmatic access.
output "vibe_bucket_url" {
  description = "Direct Cloud Object Storage bucket URL (advanced access)."
  value       = ibm_cos_bucket.vibe_bucket.website_url
}
