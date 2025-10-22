output "vibe_url" {
  description = "Your live Vibe app URL (public endpoint)."
  value       = local.vibe_url # <-- FIXED
}

output "vibe_bucket_url" {
  description = "Raw COS bucket name."
  value       = ibm_cos_bucket.vibe_bucket.bucket_name
}

# Primary link for IBM Cloud Projects UI
output "primaryoutputlink" {
  description = "Primary output link for IBM Cloud Projects."
  value       = local.vibe_url # <-- FIXED
}