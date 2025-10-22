# Random suffix to keep names unique across accounts
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Use the default resource group (adjust if you want to parameterize it)
data "ibm_resource_group" "group" {
  name = "default"
}

# IBM Cloud Object Storage Lite instance
resource "ibm_resource_instance" "vibe_instance" {
  name              = "vibe-instance-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = data.ibm_resource_group.group.id
}

# COS bucket configured for website hosting
resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.vibe_instance.id
  region_location      = var.region # <-- FIXED
  storage_class        = "standard"
  force_delete         = true
  website_main_page    = "index.html"
}

# Upload user's HTML page using base64-safe content
resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn     = ibm_cos_bucket.vibe_bucket.crn
  key            = "index.html"
  content_base64 = local.vibe_code_encoded
}