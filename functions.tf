# --- Cloud Functions Namespace ---
# A namespace is a container for your functions
resource "ibm_function_namespace" "vibe_namespace" {
  name        = "vibe-da-namespace-${random_string.suffix.result}"
  description = "Namespace for Vibe DA functions"
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
  publish      = true # Make it a web action
  exec {
    kind = "nodejs:16" # Use a modern Node.js runtime
    code = data.archive_file.push_to_cos_zip.output_b64
  }
  
  # Pass bucket details to the function as environment variables
  parameters = {
    BUCKET_NAME     = ibm_cos_bucket.vibe_bucket.bucket_name
    COS_ENDPOINT    = "s3.${ibm_cos_bucket.vibe_bucket.region_location}.cloud-object-storage.appdomain.cloud"
    COS_INSTANCE_ID = ibm_resource_instance.vibe_instance.crn
  }

  # Bind the Service ID (from iam.tf) to this function
  service_credential_key = ibm_iam_service_api_key.vibe_function_sid_key.name
}