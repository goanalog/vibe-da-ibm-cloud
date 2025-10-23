variable "vibe_code_raw" {
  description = "Paste your HTML directly — Terraform will handle encoding."
  type        = string
  default     = ""
}

# Add this new variable
variable "project_url" {
  description = "Optional: The URL of the IBM Cloud Project this DA is part of."
  type        = string
  default     = ""
}