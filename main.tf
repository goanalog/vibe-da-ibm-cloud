###############################################################
# Vibe Deployable Architecture — Main Terraform Configuration #
# Deploys an IBM Cloud Object Storage bucket and hosts your
# vibe-coded HTML application (from pasted input or index.html).
###############################################################

provider "ibm" {}

# Generate unique suffix to prevent bucket name collisions
resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# Look up the specified resource group
data "ibm_resource_group" "group" {
  name = var.resource_group
}

# Create a Cloud Object Storage instance
resource "ibm_resource_instance" "cos_instance" {
  name              = "vibe-instance-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = var.cos_plan
  location          = "global"
  resource_group_id = data.ibm_resource_group.group.id
  tags              = ["deployable-architecture", "ibm-cloud", "static-website", "vibe"]
}

# Create a COS bucket for the app
resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  region_location      = var.region
  resource_instance_id = ibm_resource_instance.cos_instance.id
  storage_class        = "standard"
  force_delete         = true
  endpoint_type        = "public"
  
  # --- FIX ---
  # Set the public-read ACL directly on the bucket
  acl = "public-read"
}

# Upload the app HTML
# If the user pasted code, use that. Otherwise, use the included index.html file.
resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = ibm_cos_bucket.bucket.region_location
  key             = "index.html"
  content         = var.html_input != "" ? var.html_input : file("index.html")
  endpoint_type   = "public"
  force_delete    = true
  
  # --- FIX ---
  # 'content_type' removed, as the provider will set it automatically.
}

# --- FIX ---
# 'ibm_cos_bucket_public_access' resource removed as it was not recognized.
# The 'acl' property on the 'ibm_cos_bucket' resource above replaces this.


# OPTIONAL: IAM Access Group (only needed if you want explicit IAM-level public read)
# You can comment this entire block out if 'acl' is sufficient.
data "ibm_iam_access_group" "public_access" {
  access_group_name = "Public Access"
}

resource "ibm_iam_access_group_policy" "public_read_policy" {
  access_group_id = data.ibm_iam_access_group.public_access.groups[0].id
  roles           = ["Object Reader"]

  resources {
    service            = "cloud-object-storage"
    resource_instance_id = ibm_resource_instance.cos_instance.guid
    resource_type      = "bucket"
    resource           = ibm_cos_bucket.bucket.bucket_name
  }
}

###############################################################
# Outputs (see outputs.tf for values)
###############################################################