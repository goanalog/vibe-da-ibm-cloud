# 🌈 Vibe Code Landing Zone — variables.tf
# Friendly inputs with reassuring descriptions.

variable "resource_group" {
  description = "Where your vibe lives organizationally. If unsure, 'default' is a chill place to start."
  type        = string
  default     = "default"
}

variable "region" {
  description = "Cosmic region for your bucket. us-south is a steady groove."
  type        = string
  default     = "us-south"
}

variable "cos_instance_name" {
  description = "A friendly name for your IBM Cloud Object Storage instance. Don’t overthink it — the vibe is in the content."
  type        = string
  default     = "vibe-coder-cos"
}

variable "bucket_name" {
  description = "Your public bucket name (lowercase, no spaces). This becomes the home of your vibe."
  type        = string
  default     = "vibe-coder-sample-bucket"
}

variable "index_html" {
  description = "Paste your full HTML here — it becomes your app’s index.html when deployed. No escaping needed; just vibes."
  type        = string
  default     = ""
}

variable "index_html_file" {
  description = "Optional path to a local HTML file (e.g., index.html). Used only if the textarea above is empty."
  type        = string
  default     = ""
}
