output "vibe_bucket_name" { description="COS bucket"; value = ibm_cos_bucket.vibe.bucket_name }
output "vibe_url" { description="Primary: IDE URL"; value = ibm_function_action.vibe_index.web_action_url }
output "vibe_upload_endpoint" { description="Manifest web action"; value = ibm_function_action.vibe_manifest.web_action_url }
output "vibe_status_endpoint" { description="Status web action"; value = ibm_function_action.vibe_status.web_action_url }
output "vibe_project_update_endpoint" { description="Project update web action"; value = ibm_function_action.vibe_update_project.web_action_url }
output "vibe_analytics_endpoint" { description="Analytics web action"; value = ibm_function_action.vibe_analytics.web_action_url }