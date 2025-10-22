#############################
# Outputs
#############################
output "vibe_url" {
  description = "Your live Vibe App URL (public endpoint)."
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/${var.website_key}"
}

output "vibe_bucket_url" {
  description = "Raw COS bucket URL."
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/"
}

# IBM Cloud Projects: promote this output as the primary link
output "primaryoutputlink" {
  description = "Primary output link for IBM Cloud Projects."
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/${var.website_key}"
}
