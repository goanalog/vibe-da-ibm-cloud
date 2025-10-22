variable "vibe_html_input_base64" {
  description = "Your HTML, Base64 encoded. (If left blank, a default sample app will be deployed)."
  type        = string
  default     = ""
}

variable "region" {
  description = "IBM Cloud region for the COS instance."
  type        = string
  default     = "us-south"
}

variable "resource_group" {
  description = "IBM Cloud resource group (use 'Default' if on a trial)."
  type        = string
  default     = "Default"
}

variable "cos_plan" {
  description = "Cloud Object Storage plan (Lite is free)."
  type        = string
  default     = "lite"
}

variable "vibe_instance_name" {
  description = "Name of your Object Storage instance."
  type        = string
  default     = "vibe-instance"
}

variable "vibe_bucket_name" {
  description = "Name of your vibe bucket."
  type        = string
  default     = "vibe-bucket"
}