output "vibe_url" {
  description = "Public URL for your deployed Vibe app"
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.vibe_bucket.bucket_name}/index.html"
}