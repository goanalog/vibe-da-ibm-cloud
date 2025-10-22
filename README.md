# 🌀 Vibe-Driven Development — Deploy Instantly

Welcome to the **Vibe Manifestation Engine** — a sample app and deployable architecture that turns your HTML, CSS, and JS into a live web experience on IBM Cloud.

## ✨ What this does
- Creates a **Cloud Object Storage (Lite)** instance and bucket
- Uploads a sample **index.html** with a live CodeMirror editor built in
- Installs an **IBM Cloud Function** that returns presigned URLs for uploads
- Makes your public URL world-viewable
- Auto-populates variables — no user input needed

## 💻 The Sample App
The page you see after deployment *is* the Vibe IDE — a living, glowing code editor where you can:
1. Edit the HTML directly in the browser
2. Hit **Manifest ✨** to push updates live to your COS bucket
3. Hit **Remix 🎛️** to reset and remix your vibe again

> All cloud access only happens after you click a button — no background requests.

## 🌐 Primary Output
Your deployed web app appears at the **Primary Output Link**:

➡️ **${vibe_url}**

This link is automatically promoted as the primary output in **IBM Cloud Projects**, so users can click straight to the live site after deployment.

## ☁️ Notes
- Uses only Lite-tier resources (no cost)
- Works with Terraform ≥ 1.12 and IBM provider v1.84
- Public bucket hosting enabled for the app
- To redeploy updates, edit your code in the IDE and hit Manifest again — no terminal required.
