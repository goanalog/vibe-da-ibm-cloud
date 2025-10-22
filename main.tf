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
}

# Upload the app HTML
# If the user pasted code, use that. Otherwise, use the included index.html file.
resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = ibm_cos_bucket.bucket.region_location
  key             = "index.html"
  content         = var.html_input != "" ? var.html_input : file("index.html")
  content_type    = "text/html; charset=utf-8"
  endpoint_type   = "public"
  force_delete    = true
  acl             = "public-read"
}

# Enable public read access at the bucket level
resource "ibm_cos_bucket_policy" "public_read" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = ibm_cos_bucket.bucket.region_location
  policy = jsonencode({
    Version   = "2.0"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = { AWS = ["*"] }
        Action    = ["s3:GetObject"]
        Resource  = ["${ibm_cos_bucket.bucket.crn}/*"]
      }
    ]
  })
}

# OPTIONAL: IAM Access Group (only needed if you want explicit IAM-level public read)
# You can comment this entire block out if ACL + bucket policy are sufficient.
data "ibm_iam_access_group" "public_access" {
  access_group_name = "Public Access"
}

resource "ibm_iam_access_group_policy" "public_read_policy" {
  access_group_id = data.ibm_iam_access_group.public_access.groups[0].id
  roles           = ["Object Reader"]

  resources {
    service              = "cloud-object-storage"
    resource_instance_id = ibm_resource_instance.cos_instance.guid
    resource_type        = "bucket"
    resource             = ibm_cos_bucket.bucket.bucket_name
  }
}

###############################################################
# Outputs (see outputs.tf for values)
###############################################################
