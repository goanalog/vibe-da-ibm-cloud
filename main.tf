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
    # Added external provider for reading environment variables
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
# Reads specific environment variables set by Projects/Schematics
data "external" "env_vars" {
  program = ["sh", "-c", "env | grep -E '^IC_PROJECT_ID=|^IC_RESOURCE_GROUP_ID=' | jq -R 'split(\"=\") | {(.[0]): .[1]}' | jq -s 'add // {}'"]
}

# --- Local Variables for Auto-Detection ---
locals {
  # Use the input variable if provided, otherwise try the env var from data source
  effective_project_id      = coalesce(var.project_id, nonsensitive(try(yamldecode(data.external.env_vars.result)["IC_PROJECT_ID"], null)), "") # Added empty string default
  effective_resource_group_id = coalesce(var.resource_group_id, nonsensitive(try(yamldecode(data.external.env_vars.result)["IC_RESOURCE_GROUP_ID"], null)), "") # Added empty string default

  # Check if essential values (auto-detected or input) are present
  # --- FIX: Enclose multi-line expression in parentheses ---
  has_required_ids = (
    local.effective_project_id != null && local.effective_project_id != "" &&
    local.effective_resource_group_id != null && local.effective_resource_group_id != "" &&
    var.config_id != null && var.config_id != ""
  )
  # --------------------------------------------------------
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
  # Use local variable
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

# --- Code Engine Project ---
resource "ibm_code_engine_project" "vibe_ce_project" {
  # Use local variable in count
  count             = var.enable_code_engine && local.has_required_ids ? 1 : 0
  name              = "vibe-project-${random_string.suffix.result}"
  # Use local variable
  resource_group_id = local.effective_resource_group_id
}

# --- COS Function Security Setup ---
resource "ibm_iam_service_id" "ce_cos_service_id" {
  count = var.enable_code_engine && local.has_required_ids ? 1 : 0
  name  = "vibe-ce-cos-api-${random_string.suffix.result}"
}
resource "ibm_cos_credentials" "hmac_keys" {
  count                = var.enable_code_engine && local.has_required_ids ? 1 : 0
  resource_instance_id = ibm_resource_instance.cos_instance.id
  role                 = "Writer"
  service_id           = ibm_iam_service_id.ce_cos_service_id[0].iam_id
  hmac                 = true
}
resource "ibm_code_engine_secret" "cos_secret" {
  count      = var.enable_code_engine && local.has_required_ids ? 1 : 0
  project_id = ibm_code_engine_project.vibe_ce_project[0].id
  name       = "cos-credentials"
  format     = "generic"
  data = {
    ACCESS_KEY_ID     = ibm_cos_credentials.hmac_keys[0].cos_hmac_keys.access_key_id
    SECRET_ACCESS_KEY = ibm_cos_credentials.hmac_keys[0].cos_hmac_keys.secret_access_key
    COS_ENDPOINT      = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud"
    COS_BUCKET        = ibm_cos_bucket.vibe_bucket.bucket_name
    COS_REGION        = var.region
  }
}

# --- Project Function Security Setup ---
resource "ibm_iam_service_id" "project_service_id" {
  count = var.enable_code_engine && local.has_required_ids ? 1 : 0
  name  = "vibe-ce-project-api-${random_string.suffix.result}"
}
resource "ibm_iam_service_policy" "project_editor_deploy_policy" {
  count              = var.enable_code_engine && local.has_required_ids ? 1 : 0
  iam_service_id     = ibm_iam_service_id.project_service_id[0].iam_id
  roles              = ["Editor", "Operator"] # Added Operator role (Verify needed roles!)

  resources {
    service = "project"
  }
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
    PROJECT_API_KEY = ibm_iam_service_api_key.project_api_key[0].api_key
    PROJECT_ID      = local.effective_project_id
    CONFIG_ID       = var.config_id
    REGION          = var.region
  }
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
  acl             = "public-read"

  content = templatefile("${path.module}/index.html.tftpl", {
    push_cos_url       = var.enable_code_engine && local.has_required_ids ? one(ibm_code_engine_function.push_to_cos[*].url) : "null"
    push_project_url   = var.enable_code_engine && local.has_required_ids ? one(ibm_code_engine_function.push_to_project[*].url) : "null"
    trigger_deploy_url = var.enable_code_engine && local.has_required_ids ? one(ibm_code_engine_function.trigger_deploy[*].url) : "null"
  })

  depends_on = [
    ibm_code_engine_function.push_to_cos,
    ibm_code_engine_function.push_to_project,
    ibm_code_engine_function.trigger_deploy
  ]
}
resource "ibm_cos_bucket_object" "error_html" {
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn
  bucket_location = var.region
  key             = var.website_error
  content         = file("${path.module}/404.html")
  acl             = "public-read"
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
    ibm_cos_bucket_object.error_html
  ]
}