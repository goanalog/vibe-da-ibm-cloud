terraform {
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.84.3" # Or your validated version
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

provider "ibm" {
  region = var.region
  # API Key is implicitly handled by Trusted Profile in Projects/Schematics
}

# --- Data Source to Read Environment Variables ---
data "external" "env_vars" {
  program = ["sh", "-c", "env | grep -E '^IC_PROJECT_ID=|^IC_RESOURCE_GROUP_ID=' | jq -R 'split(\"=\") | {(.[0]): .[1]}' | jq -s 'add // {}'"]
}

# --- Local Variables for Auto-Detection ---
locals {
  effective_project_id      = coalesce(var.project_id, nonsensitive(try(yamldecode(data.external.env_vars.result)["IC_PROJECT_ID"], null)), "")
  effective_resource_group_id = coalesce(var.resource_group_id, nonsensitive(try(yamldecode(data.external.env_vars.result)["IC_RESOURCE_GROUP_ID"], null)), "")
  has_required_ids = (
    local.effective_project_id != null && local.effective_project_id != "" &&
    local.effective_resource_group_id != null && local.effective_resource_group_id != "" &&
    var.config_id != null && var.config_id != ""
  )
}

# Random suffix for uniqueness
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Object Storage instance (Lite plan)
resource "ibm_resource_instance" "cos_instance" {
  name              = "vibe-instance-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = local.effective_resource_group_id
}

# Create COS bucket
resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"
  force_delete         = true
}

# --- Allow Public Access at Bucket Level ---
resource "ibm_cos_bucket_public_access_block" "vibe_bucket_public_access" {
  bucket_crn = ibm_cos_bucket.vibe_bucket.crn
  # Set all to false to allow public read needed for static website
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  # Ensure bucket exists before modifying its access policy
  depends_on = [ibm_cos_bucket.vibe_bucket]
}

# --- Code Engine Project ---
resource "ibm_code_engine_project" "vibe_ce_project" {
  count             = var.enable_code_engine && local.has_required_ids ? 1 : 0
  name              = "vibe-project-${random_string.suffix.result}"
  resource_group_id = local.effective_resource_group_id
}

# --- COS Function Security Setup ---
resource "ibm_iam_service_id" "ce_cos_service_id" {
  count = var.enable_code_engine && local.has_required_ids ? 1 : 0
  name  = "vibe-ce-cos-api-${random_string.suffix.result}"
}

# --- Use ibm_resource_key for HMAC ---
resource "ibm_resource_key" "cos_hmac_key" {
  count                 = var.enable_code_engine && local.has_required_ids ? 1 : 0
  name                  = "vibe-cos-hmac-key-${random_string.suffix.result}"
  resource_instance_id  = ibm_resource_instance.cos_instance.id
  role                  = "Writer" # Grant Writer role
  service_id_crn        = ibm_iam_service_id.ce_cos_service_id[0].crn # Link to Service ID

  # Specify parameters to create HMAC credentials
  parameters = {
    HMAC = true
  }
  # Ensure Service ID exists before creating key for it
  depends_on = [ibm_iam_service_id.ce_cos_service_id]
}

resource "ibm_code_engine_secret" "cos_secret" {
  count      = var.enable_code_engine && local.has_required_ids ? 1 : 0
  project_id = ibm_code_engine_project.vibe_ce_project[0].id
  name       = "cos-credentials"
  format     = "generic"
  data = {
    # Reference outputs from ibm_resource_key
    ACCESS_KEY_ID     = nonsensitive(ibm_resource_key.cos_hmac_key[0].credentials.cos_hmac_keys_access_key_id)
    SECRET_ACCESS_KEY = nonsensitive(ibm_resource_key.cos_hmac_key[0].credentials.cos_hmac_keys_secret_access_key)
    COS_ENDPOINT      = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud"
    COS_BUCKET        = ibm_cos_bucket.vibe_bucket.bucket_name
    COS_REGION        = var.region
  }
  depends_on = [ibm_resource_key.cos_hmac_key] # Ensure key exists first
}

# --- Project Function Security Setup ---
resource "ibm_iam_service_id" "project_service_id" {
  count = var.enable_code_engine && local.has_required_ids ? 1 : 0
  name  = "vibe-ce-project-api-${random_string.suffix.result}"
}
resource "ibm_iam_service_policy" "project_editor_deploy_policy" {
  count              = var.enable_code_engine && local.has_required_ids ? 1 : 0
  iam_service_id     = ibm_iam_service_id.project_service_id[0].iam_id
  roles              = ["Editor", "Operator"] # Verify needed roles

  resources {
    service = "project"
  }
  # Ensure Service ID exists before applying policy
  depends_on = [ibm_iam_service_id.project_service_id]
}
resource "ibm_iam_service_api_key" "project_api_key" {
  count          = var.enable_code_engine && local.has_required_ids ? 1 : 0
  name           = "vibe-ce-project-key-${random_string.suffix.result}"
  iam_service_id = ibm_iam_service_id.project_service_id[0].iam_id
  depends_on     = [ibm_iam_service_policy.project_editor_deploy_policy]
}
resource "ibm_code_engine_secret" "project_secret" {
  count      = var.enable_code_engine && local.has_required_ids ? 1 : 0
  project_id = ibm_code_engine_project.vibe_ce_project[0].id
  name       = "project-credentials"
  format     = "generic"
  data = {
    # --- Corrected attribute name ---
    PROJECT_API_KEY = nonsensitive(ibm_iam_service_api_key.project_api_key[0].apikey)
    # --------------------------------
    PROJECT_ID      = local.effective_project_id
    CONFIG_ID       = var.config_id
    REGION          = var.region
  }
  depends_on = [ibm_iam_service_api_key.project_api_key] # Ensure key exists first
}

# --- Code Engine Functions ---
resource "ibm_code_engine_function" "push_to_cos" {
  count           = var.enable_code_engine && local.has_required_ids ? 1 : 0
  project_id      = ibm_code_engine_project.vibe_ce_project[0].id
  name            = "push-to-cos-${random_string.suffix.result}"
  runtime         = "nodejs-18"
  code_bundle     = filebase64("${path.module}/push_to_cos.js")
  env_from_secret = [ibm_code_engine_secret.cos_secret[0].name]
  depends_on      = [ibm_code_engine_secret.cos_secret]
}
resource "ibm_code_engine_function" "push_to_project" { # Staging function
  count           = var.enable_code_engine && local.has_required_ids ? 1 : 0
  project_id      = ibm_code_engine_project.vibe_ce_project[0].id
  name            = "push-to-project-${random_string.suffix.result}"
  runtime         = "nodejs-18"
  code_bundle     = filebase64("${path.module}/push_to_project.js")
  env_from_secret = [ibm_code_engine_secret.project_secret[0].name]
  depends_on      = [ibm_code_engine_secret.project_secret]
}
resource "ibm_code_engine_function" "trigger_deploy" { # Trigger function
  count           = var.enable_code_engine && local.has_required_ids ? 1 : 0
  project_id      = ibm_code_engine_project.vibe_ce_project[0].id
  name            = "trigger-project-deploy-${random_string.suffix.result}"
  runtime         = "nodejs-18"
  code_bundle     = filebase64("${path.module}/trigger_project_deploy.js")
  env_from_secret = [ibm_code_engine_secret.project_secret[0].name]
  depends_on      = [ibm_code_engine_secret.project_secret]
}

# --- COS Website & Content Upload ---
resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn
  bucket_location = var.region
  key             = var.website_index
  # --- Removed acl argument ---

  content = templatefile("${path.module}/index.html.tftpl", {
    push_cos_url       = var.enable_code_engine && local.has_required_ids ? one(ibm_code_engine_function.push_to_cos[*].url) : "null"
    push_project_url   = var.enable_code_engine && local.has_required_ids ? one(ibm_code_engine_function.push_to_project[*].url) : "null"
    trigger_deploy_url = var.enable_code_engine && local.has_required_ids ? one(ibm_code_engine_function.trigger_deploy[*].url) : "null"
  })

  depends_on = [
    ibm_code_engine_function.push_to_cos,
    ibm_code_engine_function.push_to_project,
    ibm_code_engine_function.trigger_deploy,
    # Ensure public access is set before uploading content that relies on it
    ibm_cos_bucket_public_access_block.vibe_bucket_public_access
  ]
}
resource "ibm_cos_bucket_object" "error_html" {
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn
  bucket_location = var.region
  key             = var.website_error
  content         = file("${path.module}/404.html")
  # --- Removed acl argument ---

  # Ensure public access is set before uploading content that relies on it
  depends_on = [ibm_cos_bucket_public_access_block.vibe_bucket_public_access]
}
resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website" {
  bucket_crn    = ibm_cos_bucket.vibe_bucket.crn
  endpoint_type = "public"
  index_document {
    suffix = var.website_index
  }
  error_document {
    key = var.website_error
  }
  depends_on = [
    ibm_cos_bucket_object.index_html,
    ibm_cos_bucket_object.error_html,
    ibm_cos_bucket_public_access_block.vibe_bucket_public_access
  ]
}