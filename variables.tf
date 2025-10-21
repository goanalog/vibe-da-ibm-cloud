variable "resource_group" {
  description = "IBM Cloud resource group to use (auto-created if missing)."
  type        = string
  default     = "Default"
}

variable "region" {
  description = "IBM Cloud region where your COS bucket will be created."
  type        = string
  default     = "us-south"
}

variable "cos_instance_name" {
  description = "Name for the IBM Cloud Object Storage instance (a unique suffix will be added)."
  type        = string
  default     = "vibe-instance"
}

variable "bucket_name" {
  description = "Base name for your COS bucket (a unique suffix will be added)."
  type        = string
  default     = "vibe-bucket"
}

variable "index_html" {
  description = "Inline HTML code to host. Leave blank to use the included sample."
  type        = string
  default     = ""
}
