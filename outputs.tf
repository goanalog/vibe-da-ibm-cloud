output "vibe_bucket_name" {
  value       = ibm_cos_bucket.vibe_bucket.bucket_name
  description = "The name of the created COS bucket."
}

output "vibe_url" {
  value       = "https://s3.us-south.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.vibe_bucket.bucket_name}/index.html"
  description = "Public URL of your deployed Vibe web app."
}
