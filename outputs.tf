
output "vibe_bucket_url" {
  description = "The name of your Object Storage bucket."
  value       = ibm_cos_bucket.bucket.bucket_name
}

output "vibe_url" {
  description = "The public base URL of your bucket."
  value       = "https://${ibm_cos_bucket.bucket.bucket_name}.${var.region}.cloud-object-storage.appdomain.cloud"
}

output "vibe_bucket_public_url" {
  description = "Direct public URL of your hosted vibe app (index.html)."
  value       = "https://${ibm_cos_bucket.bucket.bucket_name}.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
}
