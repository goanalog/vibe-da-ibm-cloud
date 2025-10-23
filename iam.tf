# --- Service ID for our functions ---
resource "ibm_iam_service_id" "vibe_function_sid" {
  name        = "vibe-da-functions-sid-${random_string.suffix.result}"
  description = "Service ID for Vibe DA functions to access COS"
}

# --- API Key for the Service ID ---
resource "ibm_iam_service_api_key" "vibe_function_sid_key" {
  name           = "vibe-da-key-${random_string.suffix.result}"
  # CHANGE THIS LINE to fix Errors 3 & 4
  iam_service_id = ibm_iam_service_id.vibe_function_sid.id
  store_value    = true 
}

# --- IAM Policy: Allow function to write to our bucket ---
resource "ibm_iam_service_policy" "vibe_function_cos_policy" {
  iam_service_id = ibm_iam_service_id.vibe_function_sid.id
  roles          = ["Writer"] 

  resources {
    service              = "cloud-object-storage"
    resource_instance_id = ibm_resource_instance.vibe_instance.id
    resource_type        = "bucket"
    resource             = ibm_cos_bucket.vibe_bucket.bucket_name
  }
}

# --- ADD THIS RESOURCE ---
# This is the correct way to make the bucket public with this provider version
resource "ibm_iam_access_group_policy" "bucket_public_read_policy" {
  access_group_id = "AccessGroupId-PublicAccess"
  roles           = ["Object Reader"] # Allows public reading of objects

  resources {
    service              = "cloud-object-storage"
    resource_instance_id = ibm_resource_instance.vibe_instance.id
    resource_type        = "bucket"
    resource             = ibm_cos_bucket.vibe_bucket.bucket_name
  }
}