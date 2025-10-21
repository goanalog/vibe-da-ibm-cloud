variable "region" {
  description = "IBM Cloud region for deployment (e.g., us-south)."
  type        = string
  default     = "us-south"
}

variable "resource_group" {
  description = "IBM Cloud resource group name (case-sensitive). Usually 'Default'."
  type        = string
  default     = "Default"
}

variable "cos_instance_name" {
  description = "Name for your IBM Cloud Object Storage instance."
  type        = string
  default     = "vibe-coder-cos"
}

variable "bucket_name" {
  description = "Base name for your COS bucket (lowercase, no spaces)."
  type        = string
  default     = "vibe-coder-sample-bucket"
}

variable "index_html" {
  description = "Inline HTML code pasted by the user. Leave blank to use sample app."
  type        = string
  default     = ""
}

variable "public_access" {
  description = "Deprecated: IBM Cloud no longer allows fully public buckets. Retained for compatibility only."
  type        = bool
  default     = true
}
