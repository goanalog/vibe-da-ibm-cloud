# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Outputs for Vibe Manifestation Engine
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

output "primary_output" {
  description = "Primary URL output promoted in IBM Cloud Projects."
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.${var.region}.digitaloceanspaces.com/index.html"
}

output "vibe_url" {
  description = "Public URL of your deployed vibe."
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.${var.region}.digitaloceanspaces.com/index.html"
}

output "vibe_bucket_name" {
  description = "The name of the created IBM Cloud Object Storage bucket."
  value       = ibm_cos_bucket.vibe_bucket.bucket_name
}
