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
  name         = "vibe-push-to-cos"
  namespace_id = ibm_function_namespace.vibe_namespace.id
  publish      = true 
  
  # --- THIS BLOCK IS THE FIX ---
  # We removed the 'exec' block and are using 'zip' to pass the file path
  zip     = data.archive_file.push_to_cos_zip.output_path
  # We still need to specify the runtime
  runtime = "nodejs:16" 
  # --- END FIX ---
  
  parameters = {
    BUCKET_NAME     = ibm_cos_bucket.vibe_bucket.bucket_name
    COS_ENDPOINT    = "s3.${ibm_cos_bucket.vibe_bucket.region_location}.cloud-object-storage.appdomain.cloud"
    COS_INSTANCE_ID = ibm_resource_instance.vibe_instance.crn
  }

  service_credential_key = ibm_iam_service_api_key.vibe_function_sid_key.name
}