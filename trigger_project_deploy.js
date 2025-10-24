/**
 * IBM Cloud Code Engine (Node.js 18) — trigger_project_deploy
 * Reads Project API Key, Project ID, Config ID from env.
 * Authenticates with IAM and triggers a deployment for the config.
 */
const https = require("https");

// --- Helper: Make HTTPS requests ---
async function makeRequest(options, requestBody = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => { data += chunk; });
      res.on("end", () => {
        resolve({ statusCode: res.statusCode, headers: res.headers, body: data });
      });
    });
    req.on("error", (e) => { reject(e); });
    if (requestBody) req.write(requestBody);
    req.end();
  });
}

// --- IAM Authentication Helper ---
async function getIAMToken(apiKey) {
  const options = { hostname: "iam.cloud.ibm.com", port: 443, path: "/identity/token", method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json" }, };
  const response = await makeRequest(options, `grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${apiKey}`);
  if (response.statusCode >= 200 && response.statusCode < 300) { try { return JSON.parse(response.body).access_token; } catch (e) { throw new Error("Failed to parse IAM token response"); } }
  else { throw new Error(`IAM token request failed (${response.statusCode}): ${response.body}`); }
}

// --- Project API Trigger Deploy Helper ---
async function triggerProjectDeploy(projectId, configId, token) {
   const projectApiHost = `projects.api.cloud.ibm.com`; // Adjust if needed
   // *** Verify this is the correct endpoint for triggering deploy ***
   const path = `/v1/projects/${encodeURIComponent(projectId)}/configs/${encodeURIComponent(configId)}/deploy`;
   const options = {
      hostname: projectApiHost, port: 443, path: path, method: "POST",
      headers: { "Authorization": `Bearer ${token}`, "Accept": "application/json" }, // Content-Type might not be needed if no body
   };

   console.log(`Triggering deployment for config at: ${options.hostname}${options.path}`);
   const response = await makeRequest(options); // No body sent

   // Check for success (often 202 Accepted for async operations)
   if (response.statusCode >= 200 && response.statusCode < 300) {
       console.log(`Deployment triggered successfully (Status: ${response.statusCode}).`);
       try { return JSON.parse(response.body || '{}'); } // Attempt to parse body if present
       catch(e) { console.warn("Could not parse deploy trigger response."); return { message: "Trigger initiated." }; }
   } else {
       console.error(`Project Deploy POST failed (${response.statusCode}): ${response.body}`);
       throw new Error(`Project Deploy POST request failed (${response.statusCode}): ${response.body}`);
   }
}

// --- Main Function Logic ---
exports.main = async (params) => {
  console.log("Trigger deployment function execution started.");
  const apiKey = process.env.PROJECT_API_KEY;
  const projectId = process.env.PROJECT_ID;
  const configId = process.env.CONFIG_ID;

  if (!apiKey || !projectId || !configId) {
    console.error("Missing required environment variables.");
     // Ensure body is a string
    return { statusCode: 400, headers: { "content-type": "text/plain" }, body: "Configuration Error: Missing required environment variables." };
  }
  console.log(`Triggering deployment for ProjectID: ${projectId}, ConfigID: ${configId}`);

  try {
    console.log("Attempting to get IAM token...");
    const iamToken = await getIAMToken(apiKey);
    console.log("IAM token obtained.");

    console.log("Attempting to trigger deployment...");
    const deployResult = await triggerProjectDeploy(projectId, configId, iamToken);
    console.log("Deployment trigger API call successful.", deployResult);

    console.log("Trigger deployment function execution completed successfully.");
     // Ensure body is a string
    return {
      statusCode: 202, // 202 Accepted is common for async triggers
      headers: { "content-type": "text/plain" },
      body: `🚀 Deployment trigger initiated successfully for config ${configId}. Monitor progress in the Project UI.`
    };

  } catch (error) {
    console.error("Error during trigger deployment function execution:", error.stack || error.message);
    const errorMessage = error.response ? `${error.message} - ${error.response.body}` : error.message;
    // Ensure body is a string
    return { statusCode: 500, headers: { "content-type": "text/plain" }, body: `❌ Error triggering deployment: ${errorMessage}` };
  }
};