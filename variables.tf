# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# VARIABLES — vibe-da-ibm-cloud
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

variable "resource_group" {
  description = "The IBM Cloud resource group where your Vibe deployment will live. (Don’t worry — 'default' works fine for most users.)"
  type        = string
  default     = "default"
}

variable "region" {
  description = "Region where your COS bucket will be created (e.g. us-south, eu-de, jp-tok)."
  type        = string
  default     = "us-south"
}

variable "cos_instance_name" {
  description = "Name of your Cloud Object Storage instance. A random suffix is automatically added for uniqueness."
  type        = string
  default     = "vibe-instance"
}

variable "bucket_name" {
  description = "Name of your bucket where your app’s vibe will reside. A random suffix is appended."
  type        = string
  default     = "vibe-bucket"
}

variable "index_html" {
  description = "Optional: Paste your HTML code directly here. If left empty, the included sample app will be used."
  type        = string
  default     = ""
}
