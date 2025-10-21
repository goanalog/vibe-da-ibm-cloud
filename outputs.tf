# ~*~ Manifestations ~*~
# The universe responds. Here are the sacred links to your creation.

output "vibe_bucket_url" {
  description = "A direct resonance link to the vessel of creation (the COS bucket) itself."
  value       = "https://${ibm_cos_bucket.bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud"
}

output "vibe_url" {
  description = "The public URL where our manifested vibe now blooms for all to see."
  value       = "https://<REDACTED>.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
}

