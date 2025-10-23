# ----------------------------------------------------------
# Outputs for the Vibe Deployable Architecture
# ----------------------------------------------------------

output "vibe_bucket_website_endpoint" {
  description = "Public URL of your live Vibe site"
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/index.html"
}

output "push_cos_url" {
  description = "Invoke URL for push_to_cos Cloud Function"
  value       = local.enable_functions ? "https://${var.region}.functions.appdomain.cloud/api/v1/web/${ibm_function_namespace.ns[0].name}/default/push_to_cos" : ""
}

output "push_project_url" {
  description = "Invoke URL for push_to_project Cloud Function"
  value       = local.enable_functions ? "https://${var.region}.functions.appdomain.cloud/api/v1/web/${ibm_function_namespace.ns[0].name}/default/push_to_project" : ""
}

# Primary output link (used by IBM Cloud Projects UI)
output "primaryoutputlink" {
  description = "Primary output for IBM Cloud Projects UI – your deployed vibe site"
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/index.html"
}
