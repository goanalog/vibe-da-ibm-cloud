# 🌈 Vibe Code Landing Zone

**Stop configuring. Start feeling.**  
This deployable architecture turns a single HTML document into a live static site on IBM Cloud Object Storage — in minutes.  
Paste your vibe into a text area (or point to a file), press deploy, and breathe out.

## ✨ What you get
- **COS instance (Lite)** created for you  
- **Public bucket** with your `index.html`  
- A **shareable URL** (key output) so your vibe can be consumed immediately  

## 🧘 How to use (Catalog UI)
1. **Open** the Deployable Architecture in IBM Cloud Catalog.  
2. In **Setup**, choose your **Resource Group** and confirm **Region** (default: `us-south`).  
3. In **App Content**, either:
   - Paste your full HTML into **HTML for app**, or  
   - Provide a relative path in **Local HTML file path** (used only if the textarea is empty).  
4. Click **Deploy**. Sip tea. Observe the vibe materialize.  
5. Copy the **Vibe URL** from Outputs and share with your favorite humans.  

> No escaping required in the textarea — just paste your raw HTML.

## 🧪 Local / Terraform CLI
```bash
terraform init
terraform apply -auto-approve \
  -var "bucket_name=vibe-coder-sample-bucket" \
  -var "index_html_file=./index.html"
