output "vibe_bucket_name" { value = ibm_cos_bucket.vibe.bucket_name }
output "vibe_url" { description="Primary: live app"; value = "https://${ibm_cos_bucket.vibe.bucket_name}.${var.region}.cloud-object-storage.appdomain.cloud/index.html" }
output "vibe_upload_endpoint" { value = ibm_function_action.vibe_upload.web_action_url }
output "vibe_status" { value = "success" }
output "vibe_status_endpoint" { value = ibm_function_action.vibe_status.web_action_url }
output "vibe_project_update_endpoint" { value = ibm_function_action.vibe_project_update.web_action_url }
