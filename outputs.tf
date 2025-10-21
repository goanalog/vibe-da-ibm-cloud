# ---------------------------------------------------------------
# ⚡️ Vibe Manifestation Outputs ⚡️
# ---------------------------------------------------------------
# Consecrated endpoints for vibe consumption.
# ---------------------------------------------------------------

output "vibe_url" {
  description = "Behold the consecrated endpoint for direct vibe consumption."
  value       = "https://${var.bucket_name}.s3-web.${var.region}.cloud-object-storage.appdomain.cloud/"
}

output "vibe_bucket_url" {
  description = "Direct link to your sacred bucket."
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${var.bucket_name}/"
}