variable "cos_name" {
  description = "Name for your IBM Cloud Object Storage instance. Don't worry — we'll add a random suffix to keep it unique."
  type        = string
  default     = "vibe-bucket"
}

variable "cos_plan" {
  description = "Choose your COS service plan. The 'lite' plan is free (global only)."
  type        = string
  default     = "lite"
}

variable "cos_bucket_name" {
  description = "Base name for the bucket where your vibe-coded app will be hosted."
  type        = string
  default     = "vibe-instance"
}

variable "region" {
  description = "IBM Cloud region for resources. Ignored for COS Lite (uses 'global')."
  type        = string
  default     = "us-south"
}

variable "resource_group" {
  description = "IBM Cloud resource group to use."
  type        = string
  default     = "default"
}

variable "public_access" {
  description = "Whether to make the bucket publicly readable (recommended for simple hosting)."
  type        = bool
  default     = true
}

variable "vibe_code" {
  description = "Optional: paste your HTML vibe code here. Leave empty to use the included sample app."
  type        = string
  default     = ""
}
