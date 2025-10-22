variable "vibe_html_input_base64" {
  description = "Your HTML code, Base64 encoded. (If left blank, a default sample app will be deployed)."
  type        = string
  default     = ""
}

variable "region" {
  description = "IBM Cloud region for the COS instance."
  type        = string
  default     = "us-south"
}

variable "resource_group_name" {
  description = "IBM Cloud resource group name (use 'Default' if on a trial)."
  type        = string
  default     = "Default"
}

variable "cos_plan" {
  type        = string
  description = "Cloud Object Storage plan (Lite is free)."
  type        = string
  default     = "lite"
}

variable "vibe_instance_name" {
  description = "Prefix for your Object Storage instance name."
  type        = string
  default     = "vibe-instance"
}

variable "vibe_bucket_name" {
  description = "Prefix for your Object Storage bucket name."
  type        = string
  default     = "vibe-bucket"
}