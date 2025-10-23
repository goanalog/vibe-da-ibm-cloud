variable "region" {
  description = "IBM Cloud region for resources and COS bucket."
  type        = string
  default     = "us-south"
}

variable "resource_group" {
  description = "IBM Cloud resource group name."
  type        = string
  default     = "Default"
}

variable "bucket_prefix" {
  description = "Prefix for the public website bucket."
  type        = string
  default     = "vibe-bucket"
}

variable "enable_functions" {
  description = "Whether to deploy Cloud Functions (push_to_cos / push_to_project)."
  type        = bool
  default     = true
}


variable "resource_group_id" {
  type        = string
  description = "The ID of the IBM Cloud resource group in which to create resources."
}
