# ----------------------------------------------------------
# Input Variables for the Vibe Deployable Architecture
# ----------------------------------------------------------

variable "region" {
  description = "IBM Cloud region to deploy into (e.g., us-south, eu-gb)"
  type        = string
  default     = "us-south"
}

variable "resource_group" {
  description = "Name of the IBM Cloud resource group"
  type        = string
  default     = "default"
}

variable "bucket_prefix" {
  description = "Prefix for the Vibe COS bucket (unique per deployment)"
  type        = string
  default     = "vibe-bucket"
}

variable "enable_functions" {
  description = "Enable Cloud Functions integration for automated redeploy and updates"
  type        = bool
  default     = true
}
