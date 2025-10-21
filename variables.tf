variable "resource_group" {
  description = "IBM Cloud resource group to deploy into."
  type        = string
  default     = "Default"
}

variable "region" {
  description = "IBM Cloud region for the COS bucket."
  type        = string
  default     = "us-south"
}

variable "cos_instance_name" {
  description = "Base name for the Cloud Object Storage instance."
  type        = string
  default     = "vibe-cos"
}

variable "bucket_name" {
  description = "Prefix for the COS bucket name (a random suffix is appended)."
  type        = string
  default     = "vibe-website"
}

variable "index_html" {
  description = "HTML content for the landing page."
  type        = string
  default     = <<-EOT
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Vibe Coder — Sample App</title>
      <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    </head>
    <body class="bg-gray-900 text-white font-sans flex items-center justify-center h-screen flex-col text-center">
      <h1 class="text-4xl font-bold mb-4">✨ Welcome to Vibe Coder ✨</h1>
      <p class="text-lg mb-6">Your single-page app is live on IBM Cloud Object Storage!</p>
      <button onclick="alert('Keep vibing ✨')" class="bg-blue-600 hover:bg-blue-500 px-6 py-3 rounded-full text-white font-semibold transition">Feel the Vibe</button>
    </body>
  </html>
  EOT
}
