# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Inputs for Vibe Manifestation Engine
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

variable "region" {
  description = "IBM Cloud region for the bucket (e.g., us-south)"
  type        = string
  default     = "us-south"
}

variable "resource_group_id" {
  description = "Resource group ID for deploying the COS instance"
  type        = string
}

variable "html_input_b64" {
  description = "Base64-encoded HTML input (auto-encoded by catalog UI)"
  type        = string
}
