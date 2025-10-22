variable "region" {
  description = "IBM Cloud region"
  type        = string
  default     = "us-south"
}

variable "enable_functions" {
  description = "Enable IBM Cloud Functions presign endpoint"
  type        = bool
  default     = false
}
