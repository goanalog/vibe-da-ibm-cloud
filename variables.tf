# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Vibe Code Landing Zone — Variables
# Version: 1.0.0
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

variable "region" {
  description = "IBM Cloud region (e.g., us-south)."
  type        = string
  default     = "us-south"
}

variable "resource_group" {
  description = "IBM Cloud resource group to use."
  type        = string
  default     = "default"
}

variable "cos_instance_name" {
  description = "Friendly name for your IBM Cloud Object Storage instance."
  type        = string
  default     = "vibe-coder-cos"
}

variable "bucket_name" {
  description = "Base name for your COS bucket (lowercase, no spaces)."
  type        = string
  default     = "vibe-coder-sample-bucket"
}

variable "index_html" {
  description = "Inline HTML code pasted by the user. If left blank, a sample app is included automatically."
  type        = string
  default     = ""
}

variable "public_access" {
  description = "Whether to make the bucket publicly readable (recommended for hosting)."
  type        = bool
  default     = true
}
