variable "region" {
  description = "IBM Cloud region for COS bucket and Functions."
  type        = string
  default     = "us-south"
}

variable "resource_group" {
  description = "IBM Cloud resource group name."
  type        = string
  default     = "Default"
}