variable "region" {
  description = "IBM Cloud region for bucket objects (e.g. us-south)"
  type        = string
  default     = "us-south"
}

variable "resource_group" {
  description = "Resource group name"
  type        = string
  default     = "Default"
}

variable "enable_functions" {
  description = "Create Functions, bind COS, and expose web endpoints"
  type        = bool
  default     = true
}

variable "bucket_prefix" {
  description = "Prefix for bucket name"
  type        = string
  default     = "vibe-bucket"
}
