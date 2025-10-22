output "vibe_url" {
  description = "Your live Vibe App URL (public endpoint)"
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
}
