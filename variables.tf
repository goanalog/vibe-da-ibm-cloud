#############################
# Variables
#############################

variable "region" {
  type        = string
  description = "IBM Cloud region for the bucket (e.g., us-south)."
  default     = "us-south"
}

variable "resource_group" {
  type        = string
  description = "IBM Cloud resource group where resources will be created."
  default     = "Default"
}

variable "bucket_name_prefix" {
  type        = string
  description = "Prefix for the Object Storage bucket. A 6-char random suffix is auto-appended."
  default     = "vibe-bucket-"
}

variable "instance_name_prefix" {
  type        = string
  description = "Prefix for the Object Storage (COS) instance name. A 6-char random suffix is auto-appended."
  default     = "vibe-instance-"
}

variable "website_key" {
  type        = string
  description = "The key (path) of the website entry file uploaded to the bucket."
  default     = "index.html"
}

variable "vibe_code" {
  type        = string
  description = "Paste your HTML here. Leave empty to use the included index.html sample."
  default     = ""
}

variable "public_read" {
  type        = bool
  description = "If true, configure the bucket website for anonymous public read access."
  default     = true
}
