output "vibe_bucket_name" {
  description = "COS bucket name hosting your app"
  value       = ibm_cos_bucket.vibe.bucket_name
}

output "vibe_url" {
  description = "Public URL for your deployed Vibe app"
  value       = "https://${ibm_cos_bucket.vibe.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
}

output "vibe_presign_endpoint" {
  description = "Optional Functions endpoint for presigned upload (only when enable_functions=true)"
  value       = var.enable_functions ? "https://us-south.functions.cloud.ibm.com/api/v1/web/${ibm_function_action.presign[0].namespace}/default/${ibm_function_action.presign[0].name}.json" : null
}
