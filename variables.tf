variable "region" {
  type        = string
  description = "IBM Cloud region to deploy your vibe bucket."
  default     = "us-south"
}

variable "resource_group" {
  type        = string
  description = "IBM Cloud resource group (use 'Default' if on a trial)."
  default     = "Default"
}

variable "cos_plan" {
  type        = string
  description = "Cloud Object Storage plan (Lite is free)."
  default     = "lite"
}

variable "vibe_instance_name" {
  type        = string
  description = "Name of the IBM Cloud Object Storage instance."
  default     = "vibe-instance"
}

variable "vibe_bucket_name" {
  type        = string
  description = "Name of the Object Storage bucket where your vibes live."
  default     = "vibe-bucket"
}

variable "html_input" {
  type        = string
  description = "Paste your HTML code here — it will be automatically escaped and deployed."
  default     = ""
}