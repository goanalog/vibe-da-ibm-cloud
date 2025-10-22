variable "resource_group_id" {
  type        = string
  description = "The ID of the resource group where resources will be provisioned."
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the COS bucket will be created (e.t., 'us-south')."
  default     = "us-south"
}

variable "cos_instance_name" {
  type        = string
  description = "Name for the new IBM Cloud Object Storage instance."
  default     = "vibe-cos-instance"
}

variable "bucket_name" {
  type        = string
  description = "Name for the new public bucket. Must be globally unique."
  default     = "vibe-bucket-12345" # User should change this
}

variable "vibe_html_content" {
  type        = string
  description = "The raw HTML content to deploy. If left blank, the sample app is used."
  default     = ""
  sensitive   = true
}