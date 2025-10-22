output "vibe_url" {
  [cite_start]description = "Your live Vibe App URL (public endpoint)" [cite: 5]
  [cite_start]value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html" [cite: 5]
}

output "vibe_bucket_url" {
  description = "Raw COS bucket URL"
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/"
}

output "primaryoutputlink" {
  description = "Primary output link for IBM Cloud Projects"
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
}