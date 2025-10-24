/**
 * IBM Cloud Code Engine (Node.js 18) — push_to_project (Staging ONLY)
 * Reads Project API Key, Project ID, Config ID, Region from env.
 * Authenticates, gets config, adds timestamp, saves back (stages).
 * Returns link for review.
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
    const options = {
        hostname: "iam.cloud.ibm.com", port: 443, path: "/identity/token", method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json" },
    };
    const response = await makeRequest(options, `grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${apiKey}`);
    if (response.statusCode >= 200 && response.statusCode < 300) {
        try { return JSON.parse(response.body).access_token; } catch (e) { throw new Error("Failed to parse IAM token response"); }
    } else { throw new Error(`IAM token request failed (${response.statusCode}): ${response.body}`); }
}

// --- Project API Get Config Helper ---
async function getProjectConfig(projectId, configId, token) {
    const projectApiHost = `projects.api.cloud.ibm.com`;
    const path = `/v1/projects/${encodeURIComponent(projectId)}/configs/${encodeURIComponent(configId)}`;
    const options = {
        hostname: projectApiHost, port: 443, path: path, method: "GET",
        headers: { "Authorization": `Bearer ${token}`, "Accept": "application/json" },
    };
    console.log(`Getting config from: ${options.hostname}${options.path}`);
    const response = await makeRequest(options);
    if (response.statusCode >= 200 && response.statusCode < 300) {
        try { console.log("Successfully retrieved config."); return { config: JSON.parse(response.body), etag: response.headers['etag'] }; }
        catch (e) { throw new Error("Failed to parse Project Config GET response"); }
    } else { throw new Error(`Project Config GET request failed (${response.statusCode}): ${response.body}`); }
}

// --- Project API Update Config Helper ---
async function updateProjectConfig(projectId, configId, token, configData, etag) {
   const projectApiHost = `projects.api.cloud.ibm.com`;
   const path = `/v1/projects/${encodeURIComponent(projectId)}/configs/${encodeURIComponent(configId)}`;
   const options = {
      hostname: projectApiHost, port: 443, path: path, method: "PUT",
      headers: { "Authorization": `Bearer ${token}`, "Content-Type": "application/json", "Accept": "application/json", "If-Match": etag },
   };
   const requestBody = JSON.stringify(configData);
   console.log(`Updating config at: ${options.hostname}${options.path} with ETag: ${etag}`);
   const response = await makeRequest(options, requestBody);
   if (response.statusCode >= 200 && response.statusCode < 300) {
      try { console.log("Successfully updated config (staged)."); return JSON.parse(response.body); }
      catch (e) { throw new Error("Failed to parse Project Config PUT response"); }
   } else {
        console.error(`Project Config PUT request failed (${response.statusCode}): ${response.body}`);
        console.error(`Request Body Sent: ${requestBody.substring(0, 500)}...`);
        throw new Error(`Project Config PUT request failed (${response.statusCode}): ${response.body}`);
   }
}

// --- Main Function Logic ---
exports.main = async (params) => {
  console.log("Staging function execution started.");
  const apiKey = process.env.PROJECT_API_KEY;
  const projectId = process.env.PROJECT_ID;
  const configId = process.env.CONFIG_ID;
  const region = process.env.REGION || 'us-south';

  if (!apiKey || !projectId || !configId) {
    console.error("Missing required environment variables.");
    // Ensure body is a string
    return { statusCode: 400, headers: { "content-type": "text/plain" }, body: "Configuration Error: Missing PROJECT_API_KEY, PROJECT_ID, or CONFIG_ID in environment variables." };
  }
  console.log(`Staging for ProjectID: ${projectId}, ConfigID: ${configId}, Region: ${region}`);


  try {
    console.log("Attempting to get IAM token...");
    const iamToken = await getIAMToken(apiKey);
    console.log("IAM token obtained.");

    console.log("Attempting to get project config...");
    const { config: currentConfig, etag } = await getProjectConfig(projectId, configId, iamToken);
    if (!etag) { throw new Error("Missing ETag from GET config response."); }
    console.log(`Obtained config with ETag: ${etag}`);

    console.log("Staging update to config description...");
    const updateTimestamp = new Date().toISOString();
    let newDescription = currentConfig.description || "";
    newDescription = newDescription.replace(/\(Updated via Vibe Func: [^)]+\)/g, "").trim();
    currentConfig.description = `${newDescription} (Updated via Vibe Func: ${updateTimestamp})`;
    console.log(`New description: ${currentConfig.description}`);

    console.log("Attempting to update project config (staging)...");
    const updatedConfig = await updateProjectConfig(projectId, configId, iamToken, currentConfig, etag);
    console.log("Project config staged successfully.");

    const reviewUrl = `https://cloud.ibm.com/projects/${projectId}/configurations/${configId}/edit?region=${region}`;
    console.log(`Review URL: ${reviewUrl}`);

    console.log("Staging function execution completed successfully.");
    // Ensure body is a string
    return {
      statusCode: 200,
      headers: { "content-type": "text/plain" },
      body: `✅ Configuration staged successfully!\n\nReview changes at:\n${reviewUrl}\n\nTimestamp added: ${updateTimestamp}`
    };

  } catch (error) {
    console.error("Error during staging function execution:", error.stack || error.message);
    const errorMessage = error.response ? `${error.message} - ${error.response.body}` : error.message;
    // Ensure body is a string
    return { statusCode: 500, headers: { "content-type": "text/plain" }, body: `❌ Error staging project configuration: ${errorMessage}` };
  }
};