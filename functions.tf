# --- Cloud Functions Namespace ---
resource "ibm_function_namespace" "vibe_namespace" {
  name        = "vibe-da-namespace-${random_string.suffix.result}"
  description = "Namespace for Vibe DA functions"
  resource_group_id = data.ibm_resource_group.default.id
}

# --- Zip up the function code ---
data "archive_file" "push_to_cos_zip" {
  type        = "zip"
  source_dir  = "${path.module}/functions/push-to-cos"
  output_path = "${path.module}/functions/push-to-cos.zip"
}

# --- Cloud Function Action (Push to COS) ---
resource "ibm_function_action" "push_to_cos" {
  name    = "vibe-push-to-cos"
  namespace = ibm_function_namespace.vibe_namespace.name
  publish   = true 
  
  exec {
    kind = "nodejs:16" 
    code = filebase64(data.archive_file.push_to_cos_zip.output_path)
  }
  
  # --- THIS BLOCK IS THE FIX ---
  # Changed 'parameters' to 'annotations' to resolve the provider conflict
  annotations = jsonencode({
    BUCKET_NAME     = ibm_cos_bucket.vibe_bucket.bucket_name
    COS_ENDPOINT    = "s3.${ibm_cos_bucket.vibe_bucket.region_location}.cloud-object-storage.appdomain.cloud"
    COS_INSTANCE_ID = ibm_resource_instance.vibe_instance.crn
    # Renamed the API key variable so it's passed as a parameter
    VIBE_API_KEY    = ibm_iam_service_api_key.vibe_function_sid_key.apikey
  })
}