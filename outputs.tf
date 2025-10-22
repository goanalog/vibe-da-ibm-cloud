output "vibe_url" {
  description = "Public URL of your manifested vibe"
  value       = "https://${ibm_cos_bucket.vibe.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
}

output "primaryoutputlink" {
  description = "Primary output link for IBM Cloud Projects"
  value       = "https://${ibm_cos_bucket.vibe.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
}
