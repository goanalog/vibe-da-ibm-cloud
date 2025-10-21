variable "resource_group" {
  description = "IBM Cloud resource group name (Default)."
  type        = string
  default     = "Default"
}

variable "region" {
  description = "IBM Cloud region for deployment (e.g., us-south)."
  type        = string
  default     = "us-south"
}

variable "cos_instance_name" {
  description = "Base name for the Cloud Object Storage instance."
  type        = string
  default     = "vibe-instance"
}

variable "bucket_name" {
  description = "Base name for your COS bucket."
  type        = string
  default     = "vibe-bucket"
}

variable "cos_plan" {
  description = "COS plan type — 'lite' for free tier."
  type        = string
  default     = "lite"
}

variable "index_html" {
  description = "Paste your vibe code here. Leave empty to use the built-in sample app."
  type        = string
  default     = ""
}
