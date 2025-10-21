# 🌈 Vibe Code Landing Zone

**Stop configuring. Start feeling.**  
Deploy your HTML instantly as a hosted static site on IBM Cloud Object Storage — no config files, no frameworks, just vibes.

---

## 🚀 Quick Start (IBM Cloud Schematics)

1. Fork or clone this repo:
   ```bash
   git clone https://github.com/goanalog/vibe-da-ibm-cloud.git
   ```
2. In IBM Cloud, go to **Schematics → Workspaces → Create Workspace**.
3. Choose **Source Type:** GitHub.
4. Enter this repository URL:  
   ```
   https://github.com/goanalog/vibe-da-ibm-cloud
   ```
5. Click **Next → Generate Plan → Apply Plan**.
6. Once deployed, copy your **Vibe URL** from the outputs tab.

---

## 🧱 Inputs

| Variable | Description | Default |
|-----------|-------------|----------|
| `resource_group` | IBM Cloud Resource Group | `"default"` |
| `region` | IBM Cloud region (e.g., us-south) | `"us-south"` |
| `cos_instance_name` | Object Storage instance name | `"vibe-coder-cos"` |
| `bucket_name` | Base name for COS bucket | `"vibe-coder-sample-bucket"` |
| `index_html` | Inline HTML to host | `""` |
| `index_html_file` | Optional path to local HTML file | `""` |

---

## 🌐 Outputs

| Name | Description |
|------|--------------|
| `vibe_url` | URL of your hosted HTML app |
| `vibe_bucket_url` | Direct link to the COS bucket |

---

## 🪄 Publishing to IBM Cloud Catalog

1. Create a GitHub release (tag version `v1.0.0`):
   ```
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. Go to IBM Cloud:
   - **Catalog Management → Products → Add Product → Deployable Architecture**
3. Use:
   - **Source type:** Public GitHub repository
   - **URL:** `https://github.com/goanalog/vibe-da-ibm-cloud`
   - **Release:** `v1.0.0`

IBM Cloud will pull this repo and automatically register the deployable architecture using `catalog.json` and `manifest.yaml`.

---

## 💡 Support

Vibe Support Team  
📧 [support@vibecloud.io](mailto:support@vibecloud.io)  
💬 Issues: [GitHub Issues](https://github.com/goanalog/vibe-da-ibm-cloud/issues)

---

> “Because the best uptime is emotional uptime.” ☁️
