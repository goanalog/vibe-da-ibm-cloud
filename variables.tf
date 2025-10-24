# variables.tf (Corrected Version - Replace Entire File Contents)

variable "region" {
  description = "The IBM Cloud region where resources will be deployed (e.g., us-south, eu-de). Usually inferred from the Project."
  type        = string
  default     = "us-south" # Keep a default, but Projects often overrides this.
}

variable "project_id" {
  description = <<-EOT
    (Optional/Auto-detected) The ID of the IBM Cloud Project deploying this architecture.
    Leave blank if deploying via IBM Cloud Projects (recommended).
    If running Terraform manually, you must provide this value.
  EOT
  type        = string
  default     = null

  validation {
    # Check if input provided OR environment variable exists via data source
    condition     = var.project_id != null || coalesce(nonsensitive(try(yamldecode(data.external.env_vars.result)["IC_PROJECT_ID"], null)), "") != ""
    error_message = "The project_id must be provided if not deploying via IBM Cloud Projects (where IC_PROJECT_ID should be set)."
  }
}

variable "resource_group_id" {
  description = <<-EOT
    (Optional/Auto-detected) The ID of the IBM Cloud Resource Group for deployment.
    Leave blank if deploying via IBM Cloud Projects (recommended, uses Project's target group).
    If running Terraform manually, you must provide this value.
  EOT
  type        = string
  default     = null

  validation {
    # Check if input provided OR environment variable exists via data source
    condition     = var.resource_group_id != null || coalesce(nonsensitive(try(yamldecode(data.external.env_vars.result)["IC_RESOURCE_GROUP_ID"], null)), "") != ""
    error_message = "The resource_group_id must be provided if not deploying via IBM Cloud Projects (where IC_RESOURCE_GROUP_ID should be set)."
  }
}


variable "config_id" {
  description = <<-EOT
    (Required) The ID of the Configuration within the IBM Cloud Project for this deployment.
    Find this in the URL of your configuration page: ".../projects/{project_id}/configurations/{config_id}"
    Or, use the IBM Cloud CLI: 'ibmcloud project config-get --project-id {project_id} --id {config_name_or_id}'
  EOT
  type        = string
  default     = null # Explicitly null, making it required
  validation {
    condition     = var.config_id != null && var.config_id != ""
    error_message = "The config_id is required. See description for details on how to find it."
  }
}

variable "enable_code_engine" {
  description = "Whether to deploy IBM Cloud Code Engine functions."
  type        = bool
  default     = true
}

variable "website_index" {
  description = "Name of the index file served by the COS website."
  type        = string
  default     = "index.html"
}

variable "website_error" {
  description = "Name of the error file served by the COS website."
  type        = string
  default     = "404.html" # Corrected default
}

# Note: The ibmcloud_api_key variable was intentionally removed
#       to rely on Trusted Profiles for authentication within Projects.