# **🌈 The Vibe Manifesto: An Energetic Landing Zone**

**Stop configuring. Start feeling.**

Deploy your HTML as a hosted static artifact on the IBM Cloud's energetic grid. No complex pipelines, no framework fatigue—just pure, resonant vibes channeled through a Deployable Architecture.

## **🧘‍♀️ Your Journey to Resonance (Choose Your Path) 🧘‍♀️**

There are many paths to manifesting your creation. Choose the one that best aligns with your current energy.

### **Path 1: The Public Vibe (Self-Service from the IBM Cloud Catalog)**

This is the most direct path for any soul journeying through the IBM Cloud. It requires no setup, only intention.

1. **Journey to the Catalog:** Navigate to the public [IBM Cloud Catalog](https://cloud.ibm.com/catalog).  
2. **Seek the Vibe:** Search for **"Vibe Coder's Energetic Landing Zone"**.  
3. **Begin the Creation:** Select the offering and click **Create**. You will be guided to a Project to configure your deployment.  
4. **Configure the Flow:** Within the project, set your intentions by providing values for the Terraform variables (resource\_group, region, etc.).  
5. **Validate and Deploy:** Click **Validate** to ensure the energetic pathways are clear, then **Deploy** to manifest your creation.

### **Path 2: The Shared Vibe (For Teams via Projects & Private Catalogs)**

This path is for collectives who wish to share this blessed artifact within their own sacred organizational space.

1. **Broadcast the Vibe (Onboarding to a Private Catalog):** First, an administrator must channel the architecture into a Private Catalog.  
   * **Prepare the Offering:** Create a GitHub release to seal the energetic signature of the version you wish to share (e.g., v2.0.0).  
   * **Journey to the Catalog Sanctuary:** In the IBM Cloud, navigate to **Manage → Catalogs → Private Catalogs**.  
   * **Onboard the Vibe:** Click **Add** and provide the repository URL (https://github.com/goanalog/vibe-da-ibm-cloud) and release tag.  
2. **Manifest from Your Project:** Once onboarded, any team member can deploy.  
   * **Create a Sacred Project:** In the IBM Cloud console, navigate to **Projects** and select **Create**.  
   * **Add Your Intention:** From your project's **Catalog** tab, find and select the "Vibe Coder's Energetic Landing Zone".  
   * **Configure, Validate, and Deploy** as guided by the project's flow.


## **✨ Setting Your Intentions**

These are the technical inputs that channel your creative energy into the cloud, regardless of the path you choose.

| Variable | Vibe-Aligned Description | Default Value |
| :---- | :---- | :---- |
| resource\_group | The energetic collective (Resource Group) where our creation will reside. | "Default" |
| region | The planetary region whose frequency best aligns with our deployment. | "us-south" |
| cos\_instance\_name | The name for the Cloud Object Storage instance holding our artifact. | "vibe-cos" |
| bucket\_name | The name for the vessel (the COS bucket) that will contain your app's soul. | "vibe-website" |
| index\_html | The HTML essence, the very soul of the application, breathed into the vessel. | (a welcome page) |

## **🌍 Receiving Your Manifestations**

Upon completion of the ritual, the universe provides these sacred links as Terraform outputs.

| Name | Description |
| :---- | :---- |
| vibe\_url | The public URL where our manifested vibe now blooms for all to see. |
| vibe\_bucket\_url | A direct resonance link to the vessel of creation (the COS bucket) itself. |

