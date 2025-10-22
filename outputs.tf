output "vibe_url" {
  description = "Your live Vibe app URL (public endpoint)."
  value       = "https://s3.us-south.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.vibe_bucket.bucket_name}/index.html"
}

output "vibe_bucket_url" {
  description = "Raw COS bucket name."
  value       = ibm_cos_bucket.vibe_bucket.bucket_name
}

# Primary link for IBM Cloud Projects UI
output "primaryoutputlink" {
  description = "Primary output link for IBM Cloud Projects."
  value       = "https://s3.us-south.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.vibe_bucket.bucket_name}/index.html"
}
