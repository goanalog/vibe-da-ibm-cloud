variable "region" {
  description = "IBM Cloud region for COS bucket hosting (e.g., us-south)"
  type        = string
  default     = "us-south"
}

variable "resource_group" {
  description = "IBM Cloud Resource Group name"
  type        = string
  default     = "Default"
}

variable "enable_functions" {
  description = "Whether to deploy the Cloud Functions and bindings"
  type        = bool
  default     = true
}

variable "bucket_prefix" {
  description = "Prefix for bucket name (a random suffix will be added)"
  type        = string
  default     = "vibe-bucket"
}
