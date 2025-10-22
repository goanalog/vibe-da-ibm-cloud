variable "region" {
  description = "Region for deployment (e.g., us-south)"
  type        = string
  default     = "us-south"
}

variable "vibe_code" {
  description = "Raw HTML or code pasted by the user. Automatically encoded and deployed."
  type        = string
  default     = ""
}
