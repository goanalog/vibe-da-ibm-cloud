# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  Vibe Manifestation Engine v1.1
#  Terraform logic to manifest a user’s pasted HTML (or default sample app)
#  into an IBM Cloud Object Storage bucket with base64 auto-handling.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

provider "ibm" {}

data "ibm_resource_group" "group" {
  name = var.resource_group_name
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "ibm_resource_instance" "vibe_instance" {
  name              = "${var.vibe_instance_name}-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = var.cos_plan
  location          = var.region
  resource_group_id = data.ibm_resource_group.group.id
}

resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name          = "${var.vibe_bucket_name}-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.vibe_instance.id
  storage_class        = "standard"
  region_location      = var.region
  force_delete         = true
}

resource "ibm_cos_object" "vibe_app" {
  bucket         = ibm_cos_bucket.vibe_bucket.bucket_name
  key            = "index.html"
  content_base64 = var.vibe_html_input_base64 != "" ? var.vibe_html_input_base64 : base64encode(file("${path.module}/index.html"))
  content_type   = "text/html"
}