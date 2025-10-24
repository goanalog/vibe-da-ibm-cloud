terraform {
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.84.3" # Pinning to ensure compatibility attempt
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
}

data "external" "env_vars" {
  program = ["sh", "-c", "env | grep -E '^IC_PROJECT_ID=|^IC_RESOURCE_GROUP_ID=' | jq -R 'split(\"=\") | {(.[0]): .[1]}' | jq -s 'add // {}'"]
}

locals {
  effective_project_id      = coalesce(var.project_id, nonsensitive(try(yamldecode(data.external.env_vars.result)["IC_PROJECT_ID"], null)), "")
  effective_resource_group_id = coalesce(var.resource_group_id, nonsensitive(try(yamldecode(data.external.env_vars.result)["IC_RESOURCE_GROUP_ID"], null)), "")
  has_required_ids = (
    local.effective_project_id != null && local.effective_project_id != "" &&
    local.effective_resource_group_id != null && local.effective_resource_group_id != "" &&
    var.config_id != null && var.config_id != ""
  )
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "vibe-instance-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = local.effective_resource_group_id
}

resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"
  force_delete         = true
}

# --- REMOVED ibm_cos_bucket_public_access_block ---
# If 403 error returns, we need another way to set public access, maybe IAM policy?

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

resource "ibm_resource_key" "cos_hmac_key" {
  count                 = var.enable_code_engine && local.has_required_ids ? 1 : 0
  name                  = "vibe-cos-hmac-key-${random_string.suffix.result}"
  resource_instance_id  = ibm_resource_instance.cos_instance.id
  role                  = "Writer"
  # --- FIX: Try serviceid_crn again ---
  serviceid_crn         = ibm_iam_service_id.ce_cos_service_id[0].crn
  # -----------------------------------

  parameters = {
    HMAC = true
  }
  depends_on = [ibm_iam_service_id.ce_cos_service_id]
}

resource "ibm_code_engine_secret" "cos_secret" {
  count      = var.enable_code_engine && local.has_required_ids ? 1 : 0
  project_id = ibm_code_engine_project.vibe_ce_project[0].id
  name       = "cos-credentials"
  format     = "generic"
  data = {
    ACCESS_KEY_ID     = nonsensitive(ibm_resource_key.cos_hmac_key[0].credentials.cos_hmac_keys_access_key_id)
    SECRET_ACCESS_KEY = nonsensitive(ibm_resource_key.cos_hmac_key[0].credentials.cos_hmac_keys_secret_access_key)
    COS_ENDPOINT      = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud"
    COS_BUCKET        = ibm_cos_bucket.vibe_bucket.bucket_name
    COS_REGION        = var.region
  }
  depends_on = [ibm_resource_key.cos_hmac_key]
}

# --- Project Function Security Setup ---
resource "ibm_iam_service_id" "project_service_id" {
  count = var.enable_code_engine && local.has_required_ids ? 1 : 0
  name  = "vibe-ce-project-api-${random_string.suffix.result}"
}
resource "ibm_iam_service_policy" "project_editor_deploy_policy" {
  count              = var.enable_code_engine && local.has_required_ids ? 1 : 0
  iam_service_id     = ibm_iam_service_id.project_service_id[0].iam_id
  roles              = ["Editor", "Operator"]

  resources {
    service = "project"
  }
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
    PROJECT_API_KEY = nonsensitive(ibm_iam_service_api_key.project_api_key[0].apikey)
    PROJECT_ID      = local.effective_project_id
    CONFIG_ID       = var.config_id
    REGION          = var.region
  }
  depends_on = [ibm_iam_service_api_key.project_api_key]
}

# --- Code Engine Functions ---
resource "ibm_code_engine_function" "push_to_cos" {
  count      = var.enable_code_engine && local.has_required_ids ? 1 : 0
  project_id = ibm_code_engine_project.vibe_ce_project[0].id
  name       = "push-to-cos-${random_string.suffix.result}"
  runtime    = "nodejs-18"

  # --- FIX: Define code using nested 'code' block ---
  code {
    source_type = "inline"
    source_code = file("${path.module}/push_to_cos.js")
  }
  # ----------------------------------------------------

  # --- FIX: Define env vars using 'env_variables' map ---
  env_variables = {
    ACCESS_KEY_ID     = "{secret_key_ref: {name: ${ibm_code_engine_secret.cos_secret[0].name}, key: ACCESS_KEY_ID}}"
    SECRET_ACCESS_KEY = "{secret_key_ref: {name: ${ibm_code_engine_secret.cos_secret[0].name}, key: SECRET_ACCESS_KEY}}"
    COS_ENDPOINT      = "{secret_key_ref: {name: ${ibm_code_engine_secret.cos_secret[0].name}, key: COS_ENDPOINT}}"
    COS_BUCKET        = "{secret_key_ref: {name: ${ibm_code_engine_secret.cos_secret[0].name}, key: COS_BUCKET}}"
    COS_REGION        = "{secret_key_ref: {name: ${ibm_code_engine_secret.cos_secret[0].name}, key: COS_REGION}}"
  }
  # --------------------------------------------------------
  depends_on = [ibm_code_engine_secret.cos_secret]
}

resource "ibm_code_engine_function" "push_to_project" { # Staging function
  count      = var.enable_code_engine && local.has_required_ids ? 1 : 0
  project_id = ibm_code_engine_project.vibe_ce_project[0].id
  name       = "push-to-project-${random_string.suffix.result}"
  runtime    = "nodejs-18"

  # --- FIX: Define code using nested 'code' block ---
  code {
    source_type = "inline"
    source_code = file("${path.module}/push_to_project.js")
  }
  # ----------------------------------------------------

  # --- FIX: Define env vars using 'env_variables' map ---
  env_variables = {
    PROJECT_API_KEY = "{secret_key_ref: {name: ${ibm_code_engine_secret.project_secret[0].name}, key: PROJECT_API_KEY}}"
    PROJECT_ID      = "{secret_key_ref: {name: ${ibm_code_engine_secret.project_secret[0].name}, key: PROJECT_ID}}"
    CONFIG_ID       = "{secret_key_ref: {name: ${ibm_code_engine_secret.project_secret[0].name}, key: CONFIG_ID}}"
    REGION          = "{secret_key_ref: {name: ${ibm_code_engine_secret.project_secret[0].name}, key: REGION}}"
  }
  # --------------------------------------------------------
  depends_on = [ibm_code_engine_secret.project_secret]
}

resource "ibm_code_engine_function" "trigger_deploy" { # Trigger function
  count      = var.enable_code_engine && local.has_required_ids ? 1 : 0
  project_id = ibm_code_engine_project.vibe_ce_project[0].id
  name       = "trigger-project-deploy-${random_string.suffix.result}"
  runtime    = "nodejs-18"

  # --- FIX: Define code using nested 'code' block ---
  code {
    source_type = "inline"
    source_code = file("${path.module}/trigger_project_deploy.js")
  }
  # ----------------------------------------------------

  # --- FIX: Define env vars using 'env_variables' map ---
  env_variables = {
    PROJECT_API_KEY = "{secret_key_ref: {name: ${ibm_code_engine_secret.project_secret[0].name}, key: PROJECT_API_KEY}}"
    PROJECT_ID      = "{secret_key_ref: {name: ${ibm_code_engine_secret.project_secret[0].name}, key: PROJECT_ID}}"
    CONFIG_ID       = "{secret_key_ref: {name: ${ibm_code_engine_secret.project_secret[0].name}, key: CONFIG_ID}}"
    REGION          = "{secret_key_ref: {name: ${ibm_code_engine_secret.project_secret[0].name}, key: REGION}}"
  }
  # --------------------------------------------------------
  depends_on = [ibm_code_engine_secret.project_secret]
}


# --- COS Website & Content Upload ---
resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn
  bucket_location = var.region
  key             = var.website_index
  # acl removed

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
  # acl removed
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