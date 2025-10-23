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

# --- NEW: Cloud Functions Package ---
resource "ibm_function_package" "vibe_package" {
  name      = "vibe-da-package"
  namespace = ibm_function_namespace.vibe_namespace.name

  # This binds our COS Service ID key to the entire package
  # This is the new way we're passing credentials
  bind_services = {
    (ibm_resource_instance.vibe_instance.name) = ibm_iam_service_api_key.vibe_function_sid_key.name
  }
}

# --- Cloud Function Action (Push to COS) ---
resource "ibm_function_action" "push_to_cos" {
  name    = "vibe-push-to-cos"
  namespace = ibm_function_namespace.vibe_namespace.name
  publish   = true 
  
  # This tells the action to live inside our new package
  package_name = ibm_function_package.vibe_package.name
  
  exec {
    kind = "nodejs:16" 
    code = filebase64(data.archive_file.push_to_cos_zip.output_path)
  }
  
  # Now we're only passing the non-credential parameters
  parameters = jsonencode({
    BUCKET_NAME     = ibm_cos_bucket.vibe_bucket.bucket_name
    COS_ENDPOINT    = "s3.${ibm_cos_bucket.vibe_bucket.region_location}.cloud-object-storage.appdomain.cloud"
    COS_INSTANCE_ID = ibm_resource_instance.vibe_instance.crn
  })
}