variable "region" {
  description = "IBM Cloud region for the deployment."
  type        = string
  default     = "us-south"
}

variable "resource_group" {
  description = "Name of the IBM Cloud resource group (use 'Default' if on a trial account)."
  type        = string
  default     = "Default"
}

variable "cos_plan" {
  description = "Plan for the Cloud Object Storage instance (Lite is free)."
  type        = string
  default     = "lite"
}

variable "html_input" {
  description = "Paste your vibe-coded HTML here. If left empty, the included sample app (index.html) will be used automatically."
  type        = string
  default     = ""
}
