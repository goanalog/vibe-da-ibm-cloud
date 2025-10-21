variable "resource_group" {
  description = "Existing IBM Cloud resource group to use."
  type        = string
  default     = "Default"
}

variable "region" {
  description = "Region for the COS bucket (e.g., us-south)."
  type        = string
  default     = "us-south"
}

variable "cos_instance_name" {
  description = "Base name for the COS instance (a random suffix is appended)."
  type        = string
  default     = "vibe-cos"
}

variable "bucket_name" {
  description = "Base name for the COS bucket (a random suffix is appended)."
  type        = string
  default     = "vibe-bucket"
}

variable "index_html" {
  description = "Paste your vibe code (HTML) here. If left empty, the repo's index.html will be used automatically."
  type        = string
  default     = ""
  sensitive   = false
}
