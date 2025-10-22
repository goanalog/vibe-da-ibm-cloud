provider "ibm" {}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

data "ibm_resource_group" "group" {
  name = var.resource_group
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "vibe-instance-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = var.cos_plan
  location          = "global"
  resource_group_id = data.ibm_resource_group.group.id
  tags              = ["deployable-architecture", "ibm-cloud", "static-website", "vibe"]
}

resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  region_location      = var.region
  resource_instance_id = ibm_resource_instance.cos_instance.id
  storage_class        = "standard"
  force_delete         = true
  endpoint_type        = "public"
}

resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = ibm_cos_bucket.bucket.region_location
  key             = "index.html"
  content         = var.html_input != "" ? var.html_input : file("index.html")
  endpoint_type   = "public"
  force_delete    = true
}

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
