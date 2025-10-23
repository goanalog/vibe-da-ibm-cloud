# --- Service ID for our functions ---
# This gives our functions their own identity
resource "ibm_iam_service_id" "vibe_function_sid" {
  name        = "vibe-da-functions-sid-${random_string.suffix.result}"
  description = "Service ID for Vibe DA functions to access COS"
}

# --- API Key for the Service ID ---
resource "ibm_iam_service_api_key" "vibe_function_sid_key" {
  name           = "vibe-da-key-${random_string.suffix.result}"
  service_id     = ibm_iam_service_id.vibe_function_sid.id
  store_value    = true # Store the key so the function can use it
}

# --- IAM Policy: Allow function to write to our bucket ---
resource "ibm_iam_service_policy" "vibe_function_cos_policy" {
  iam_service_id = ibm_iam_service_id.vibe_function_sid.id
  roles          = ["Writer"] # "Writer" role to upload/overwrite objects

  resources {
    service              = "cloud-object-storage"
    # Scope this policy *only* to the instance we created
    resource_instance_id = ibm_resource_instance.vibe_instance.id
    # And even further, *only* to the bucket we created
    resource_type        = "bucket"
    resource             = ibm_cos_bucket.vibe_bucket.bucket_name
  }
}