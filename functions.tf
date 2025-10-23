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
  # FIX 1: Use 'namespace' not 'namespace_id'
  namespace = ibm_function_namespace.vibe_namespace.name
  publish   = true 
  
  # FIX 2: 'exec' block is required
  exec {
    # FIX 3: 'runtime' ('kind') goes inside 'exec'
    kind = "nodejs:16" 
    # FIX 4: Use filebase64() to read the zip file content
    code = filebase64(data.archive_file.push_to_cos_zip.output_path)
  }
  
  # FIX 5: 'parameters' must be a JSON string
  parameters = jsonencode({
    BUCKET_NAME     = ibm_cos_bucket.vibe_bucket.bucket_name
    COS_ENDPOINT    = "s3.${ibm_cos_bucket.vibe_bucket.region_location}.cloud-object-storage.appdomain.cloud"
    COS_INSTANCE_ID = ibm_resource_instance.vibe_instance.crn
    # FIX 6: Pass the API key as a parameter
    __OW_API_KEY    = ibm_iam_service_api_key.vibe_function_sid_key.api_key
  })

  # FIX 7: 'service_credential_key' is removed
}