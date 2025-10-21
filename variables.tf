# ~*~ Intentions ~*~
# Set your energetic intentions for this deployment.
# Each variable is a focal point for your creative will.

variable "resource_group" {
  description = "The energetic collective (Resource Group) where our creation will blossom."
  type        = string
  default     = "Default"
}

variable "region" {
  description = "The planetary region whose frequency best aligns with our deployment's spirit."
  type        = string
  default     = "us-south"
}

variable "cos_instance_name" {
  description = "A sacred name for the Cloud Object Storage instance, our artifact's astral home."
  type        = string
  default     = "vibe-cos"
}

variable "bucket_name" {
  description = "The name for the vessel (the COS bucket) that will hold your application's soul."
  type        = string
  default     = "vibe-website"
}

variable "index_html" {
  description = "The HTML essence, the very soul of our application, to be breathed into the vessel."
  type        = string
  default     = <<-EOT
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Vibrational Alignment Manifested</title>
      <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
      <style>
        @keyframes pulse {
          0%, 100% { transform: scale(1); box-shadow: 0 0 20px rgba(147, 197, 253, 0.4); }
          50% { transform: scale(1.05); box-shadow: 0 0 35px rgba(147, 197, 253, 0.7); }
        }
        .pulse-btn { animation: pulse 2.5s infinite; }
      </style>
    </head>
    <body class="bg-gray-900 text-white font-sans flex items-center justify-center h-screen flex-col text-center p-4">
      <div class="max-w-2xl">
        <h1 class="text-5xl font-bold mb-4 bg-clip-text text-transparent bg-gradient-to-r from-blue-400 to-purple-500">✨ Your Vibe is Live ✨</h1>
        <p class="text-xl mb-8 text-gray-300">Your single-page artifact has successfully blossomed on the IBM Cloud's energetic grid.</p>
        <p class="text-md mb-8 text-gray-400">This is not just a deployment. It is a digital mantra, a pixelated prayer. You did not push code; you invited it to bloom.</p>
        <button onclick="document.getElementById('vibe-modal').style.display='flex'" class="pulse-btn bg-blue-600 hover:bg-blue-500 px-8 py-4 rounded-full text-white font-semibold transition-transform duration-300">Attune to the Frequency</button>
      </div>
      <!-- Modal for Vibe Reading -->
      <div id="vibe-modal" class="fixed inset-0 bg-black bg-opacity-75 items-center justify-center" style="display:none;">
        <div class="bg-gray-800 rounded-lg p-8 text-center border border-purple-500 shadow-xl">
          <h2 class="text-2xl font-bold mb-4">Vibrational Reading:</h2>
          <p class="text-lg text-green-400">✨ Harmonious & Resonant ✨</p>
          <button onclick="document.getElementById('vibe-modal').style.display='none'" class="mt-6 bg-purple-600 hover:bg-purple-500 px-6 py-2 rounded-full">Close Portal</button>
        </div>
      </div>
    </body>
  </html>
  EOT
}

