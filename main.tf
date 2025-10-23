# main.tf

provider "ibm" {}

# ADD THIS DATA SOURCE
data "ibm_resource_group" "default" {
  is_default = true
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  # This part is correct
  html_content = templatefile("${path.module}/index.html.tftpl", {
    function_push_url    = ibm_function_action.push_to_cos.web_action_url
    function_request_url = "" 
    project_url          = var.project_url
  })
}

resource "ibm_resource_instance" "vibe_instance" {
  name              = "vibe-instance-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  # ADD THIS LINE
  resource_group_id = data.ibm_resource_group.default.id
}

resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.vibe_instance.id
  storage_class        = "standard"
  region_location      = "us-south"
  force_delete         = true
  
  # ADD THIS BLOCK to enable static website hosting
  static_website {
    index_document = "index.html"
  }
}

resource "ibm_cos_bucket_object" "vibe_code" {
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn
  bucket_location = ibm_cos_bucket.vibe_bucket.region_location

  key     = "index.html"
  content = local.html_content
  etag    = md5(local.html_content)
}

# REMOVE the entire 'ibm_cos_bucket_policy' resource block.
# We will add the correct policy to 'iam.tf'