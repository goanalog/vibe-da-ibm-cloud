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
  # Check for resource group ID needed for base resources
  has_required_base_ids = (local.effective_resource_group_id != null && local.effective_resource_group_id != "")
}

# Random suffix for uniqueness
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Object Storage instance (Lite plan)
resource "ibm_resource_instance" "cos_instance" {
  count             = local.has_required_base_ids ? 1 : 0
  name              = "vibe-instance-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = local.effective_resource_group_id
}

# Create COS bucket
resource "ibm_cos_bucket" "vibe_bucket" {
  count                = local.has_required_base_ids ? 1 : 0
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance[0].id
  region_location      = var.region
  storage_class        = "standard"
  force_delete         = true
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

resource "ibm_resource_key" "cos_hmac_key" {
  count                 = var.enable_code_engine && local.has_required_ids ? 1 : 0
  name                  = "vibe-cos-hmac-key-${random_string.suffix.result}"
  resource_instance_id  = ibm_resource_instance.cos_instance[0].id
  role                  = "Writer"
  # serviceid_crn or iam_service_id removed

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
    ACCESS_KEY_ID     = nonsensitive(try(ibm_resource_key.cos_hmac_key[0].credentials.cos_hmac_keys_access_key_id, "key-error"))
    SECRET_ACCESS_KEY = nonsensitive(try(ibm_resource_key.cos_hmac_key[0].credentials.cos_hmac_keys_secret_access_key, "secret-error"))
    COS_ENDPOINT      = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud"
    COS_BUCKET        = ibm_cos_bucket.vibe_bucket[0].bucket_name
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
    PROJECT_API_KEY = nonsensitive(try(ibm_iam_service_api_key.project_api_key[0].apikey, "apikey-error"))
    PROJECT_ID      = local.effective_project_id
    CONFIG_ID       = var.config_id
    REGION          = var.region
  }
  depends_on = [ibm_iam_service_api_key.project_api_key]
}

# --- Code Engine Functions ---
# Using the schema expected by newer provider versions, hoping v1.84.3 might partially support it
# If these fail, the provider needs updating or functions need removing.
resource "ibm_code_engine_function" "push_to_cos" {
  count      = var.enable_code_engine && local.has_required_ids ? 1 : 0
  project_id = ibm_code_engine_project.vibe_ce_project[0].id
  name       = "push-to-cos-${random_string.suffix.result}"
  runtime    = "nodejs-18"

  code_reference = "data:application/javascript;base64,${base64encode(file("${path.module}/push_to_cos.js"))}"

  run_env_variables = [
    { type = "secret_key_reference", name = "ACCESS_KEY_ID", reference = ibm_code_engine_secret.cos_secret[0].name, key = "ACCESS_KEY_ID" },
    { type = "secret_key_reference", name = "SECRET_ACCESS_KEY", reference = ibm_code_engine_secret.cos_secret[0].name, key = "SECRET_ACCESS_KEY" },
    { type = "secret_key_reference", name = "COS_ENDPOINT", reference = ibm_code_engine_secret.cos_secret[0].name, key = "COS_ENDPOINT" },
    { type = "secret_key_reference", name = "COS_BUCKET", reference = ibm_code_engine_secret.cos_secret[0].name, key = "COS_BUCKET" },
    { type = "secret_key_reference", name = "COS_REGION", reference = ibm_code_engine_secret.cos_secret[0].name, key = "COS_REGION" }
  ]
  depends_on = [ibm_code_engine_secret.cos_secret]
}

resource "ibm_code_engine_function" "push_to_project" {
  count      = var.enable_code_engine && local.has_required_ids ? 1 : 0
  project_id = ibm_code_engine_project.vibe_ce_project[0].id
  name       = "push-to-project-${random_string.suffix.result}"
  runtime    = "nodejs-18"

  code_reference = "data:application/javascript;base64,${base64encode(file("${path.module}/push_to_project.js"))}"

  run_env_variables = [
    { type = "secret_key_reference", name = "PROJECT_API_KEY", reference = ibm_code_engine_secret.project_secret[0].name, key = "PROJECT_API_KEY" },
    { type = "secret_key_reference", name = "PROJECT_ID", reference = ibm_code_engine_secret.project_secret[0].name, key = "PROJECT_ID" },
    { type = "secret_key_reference", name = "CONFIG_ID", reference = ibm_code_engine_secret.project_secret[0].name, key = "CONFIG_ID" },
    { type = "secret_key_reference", name = "REGION", reference = ibm_code_engine_secret.project_secret[0].name, key = "REGION" }
  ]
  depends_on = [ibm_code_engine_secret.project_secret]
}

resource "ibm_code_engine_function" "trigger_deploy" {
  count      = var.enable_code_engine && local.has_required_ids ? 1 : 0
  project_id = ibm_code_engine_project.vibe_ce_project[0].id
  name       = "trigger-project-deploy-${random_string.suffix.result}"
  runtime    = "nodejs-18"

  code_reference = "data:application/javascript;base64,${base64encode(file("${path.module}/trigger_project_deploy.js"))}"

  run_env_variables = [
    { type = "secret_key_reference", name = "PROJECT_API_KEY", reference = ibm_code_engine_secret.project_secret[0].name, key = "PROJECT_API_KEY" },
    { type = "secret_key_reference", name = "PROJECT_ID", reference = ibm_code_engine_secret.project_secret[0].name, key = "PROJECT_ID" },
    { type = "secret_key_reference", name = "CONFIG_ID", reference = ibm_code_engine_secret.project_secret[0].name, key = "CONFIG_ID" },
    { type = "secret_key_reference", name = "REGION", reference = ibm_code_engine_secret.project_secret[0].name, key = "REGION" }
  ]
  depends_on = [ibm_code_engine_secret.project_secret]
}


# --- COS Website & Content Upload ---
resource "ibm_cos_bucket_object" "index_html" {
  count           = local.has_required_ids ? 1 : 0
  bucket_crn      = ibm_cos_bucket.vibe_bucket[0].crn
  bucket_location = var.region
  key             = var.website_index
  # acl removed

  content = templatefile("${path.module}/index.html.tftpl", {
    push_cos_url       = var.enable_code_engine && local.has_required_ids ? one(ibm_code_engine_function.push_to_cos[*].url) : "null"
    push_project_url   = var.enable_code_engine && local.has_required_ids ? one(ibm_code_engine_function.push_to_project[*].url) : "null"
    trigger_deploy_url = var.enable_code_engine && local.has_required_ids ? one(ibm_code_engine_function.trigger_deploy[*].url) : "null"
  })

  # --- FIX: Removed dependency on policy causing cycle ---
  depends_on = [
    ibm_code_engine_function.push_to_cos,
    ibm_code_engine_function.push_to_project,
    ibm_code_engine_function.trigger_deploy
    # Ensure bucket exists, but don't depend on policy here
    # ibm_cos_bucket_policy.public_read_policy - REMOVED
  ]
}
resource "ibm_cos_bucket_object" "error_html" {
  count           = local.has_required_ids ? 1 : 0
  bucket_crn      = ibm_cos_bucket.vibe_bucket[0].crn
  bucket_location = var.region
  key             = var.website_error
  content         = file("${path.module}/404.html")
  # acl removed

  # --- FIX: Removed dependency on policy causing cycle ---
  # depends_on = [ibm_cos_bucket_policy.public_read_policy] - REMOVED
}

# --- Add IAM Bucket Policy for Public Read Access ---
data "ibm_iam_policy_template_latest" "object_reader_template" {
  template_type = "service"
  service_name  = "cloud-object-storage"
  policy_type   = "access"
  roles         = ["Object Reader"]
}

resource "ibm_cos_bucket_policy" "public_read_policy" {
  count                = local.has_required_ids ? 1 : 0
  bucket_crn           = ibm_cos_bucket.vibe_bucket[0].crn
  bucket_location      = var.region
  iam_policy_id        = data.ibm_iam_policy_template_latest.object_reader_template.policy_id
  iam_access_group_ids = []
  iam_user_ids         = []
  public_access        = true

  # Depend on objects being created first
  depends_on = [
    ibm_cos_bucket_object.index_html,
    ibm_cos_bucket_object.error_html
  ]
}
# ---------------------------------------------------

resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website" {
  count         = local.has_required_ids ? 1 : 0
  bucket_crn    = ibm_cos_bucket.vibe_bucket[0].crn
  endpoint_type = "public"
  index_document {
    suffix = var.website_index
  }
  error_document {
    key = var.website_error
  }
  # Depend on the policy being applied *after* objects exist
  depends_on = [
    ibm_cos_bucket_policy.public_read_policy
  ]
}