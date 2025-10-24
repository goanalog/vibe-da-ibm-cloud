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
  }
}

provider "ibm" {
  region = var.region
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
  resource_group_id = var.resource_group_id
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
  count             = var.enable_code_engine ? 1 : 0
  name              = "vibe-project-${random_string.suffix.result}"
  resource_group_id = var.resource_group_id
}

# --- Automated Security Setup ---

# 1. Create a Service ID for the CE Function
resource "ibm_iam_service_id" "ce_service_id" {
  count = var.enable_code_engine ? 1 : 0
  name  = "vibe-ce-service-id-${random_string.suffix.result}"
}

# 2. Create HMAC (Access Key/Secret Key) credentials for the Service ID
#    Scoped to "Writer" role *only* for this COS instance
resource "ibm_cos_credentials" "hmac_keys" {
  count                = var.enable_code_engine ? 1 : 0
  resource_instance_id = ibm_resource_instance.cos_instance.id
  role                 = "Writer"
  service_id           = ibm_iam_service_id.ce_service_id[0].iam_id
  hmac                 = true
}

# 3. Create a Code Engine secret to hold the keys and bucket info
resource "ibm_code_engine_secret" "cos_secret" {
  count      = var.enable_code_engine ? 1 : 0
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

# --- Code Engine Functions ---

# 1. Deploy the 'push_to_cos' function
resource "ibm_code_engine_function" "push_to_cos" {
  count           = var.enable_code_engine ? 1 : 0
  project_id      = ibm_code_engine_project.vibe_ce_project[0].id
  name            = "push-to-cos-${random_string.suffix.result}"
  runtime         = "nodejs-18"
  code_bundle     = filebase64("${path.module}/push_to_cos.js")
  # Binds the secret as environment variables
  env_from_secret = [ibm_code_engine_secret.cos_secret[0].name]
}

# 2. Deploy the 'push_to_project' function
resource "ibm_code_engine_function" "push_to_project" {
  count       = var.enable_code_engine ? 1 : 0
  project_id  = ibm_code_engine_project.vibe_ce_project[0].id
  name        = "push-to-project-${random_string.suffix.result}"
  runtime     = "nodejs-18"
  code_bundle = filebase64("${path.module}/push_to_project.js")
}

# --- COS Website & Content Upload ---

# Upload index.html (using templating)
resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn
  bucket_location = var.region
  key             = "index.html"
  acl             = "public-read" # <-- Your fix for public access!

  # Injects the live CE function URLs into the HTML
  content = templatefile("${path.module}/index.html.tftpl", {
    push_cos_url     = var.enable_code_engine ? ibm_code_engine_function.push_to_cos[0].url : "null"
    push_project_url = var.enable_code_engine ? ibm_code_engine_function.push_to_project[0].url : "null"
  })

  # Ensures functions are created before we try to get their URLs
  depends_on = [
    ibm_code_engine_function.push_to_cos,
    ibm_code_engine_function.push_to_project
  ]
}

# Upload error page
resource "ibm_cos_bucket_object" "error_html" {
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn
  bucket_location = var.region
  key             = "404.html"
  content         = file("${path.module}/404.html")
  acl             = "public-read" # <-- Your fix for public access!
}

# Configure bucket for static website hosting (Corrected)
resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website" {
  bucket_crn    = ibm_cos_bucket.vibe_bucket.crn
  endpoint_type = "public" # Use public endpoint for website URL

  index_document {
    suffix = var.website_index
  }

  error_document {
    key = var.website_error
  }
}