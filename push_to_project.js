/**
 * IBM Cloud Code Engine (Node.js 18) — push_to_project
 * Reads Project API Key, Project ID, and Config ID from environment variables.
 * Authenticates with IAM, retrieves the current configuration, adds a timestamp
 * to its description, and saves it back to the Project service ("staging").
 * Returns a link to the Project UI for review.
 */
const https = require("https");

// --- Helper: Make HTTPS requests ---
async function makeRequest(options, requestBody = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => { data += chunk; });
      res.on("end", () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: data,
        });
      });
    });
    req.on("error", (e) => { reject(e); });
    if (requestBody) {
      req.write(requestBody);
    }
    req.end();
  });
}

// --- IAM Authentication Helper ---
async function getIAMToken(apiKey) {
  const options = {
    hostname: "iam.cloud.ibm.com",
    port: 443,
    path: "/identity/token",
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "Accept": "application/json",
    },
  };
  const requestBody = `grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${apiKey}`;
  const response = await makeRequest(options, requestBody);

  if (response.statusCode >= 200 && response.statusCode < 300) {
    try {
      const parsedData = JSON.parse(response.body);
      return parsedData.access_token;
    } catch (e) {
      throw new Error("Failed to parse IAM token response");
    }
  } else {
    throw new Error(`IAM token request failed (${response.statusCode}): ${response.body}`);
  }
}

// --- Project API Get Config Helper ---
async function getProjectConfig(projectId, configId, token) {
  const projectApiHost = `projects.api.cloud.ibm.com`; // Adjust if needed for region
  const path = `/v1/projects/${encodeURIComponent(projectId)}/configs/${encodeURIComponent(configId)}`;
  const options = {
    hostname: projectApiHost,
    port: 443,
    path: path,
    method: "GET",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Accept": "application/json",
    },
  };
  console.log(`Getting config from: ${options.hostname}${options.path}`);
  const response = await makeRequest(options);

  if (response.statusCode >= 200 && response.statusCode < 300) {
    try {
      console.log("Successfully retrieved config.");
      return { config: JSON.parse(response.body), etag: response.headers['etag'] }; // Return config and ETag
    } catch (e) {
      throw new Error("Failed to parse Project Config GET response");
    }
  } else {
    throw new Error(`Project Config GET request failed (${response.statusCode}): ${response.body}`);
  }
}

// --- Project API Update Config Helper ---
async function updateProjectConfig(projectId, configId, token, configData, etag) {
   const projectApiHost = `projects.api.cloud.ibm.com`; // Adjust if needed for region
   const path = `/v1/projects/${encodeURIComponent(projectId)}/configs/${encodeURIComponent(configId)}`;
   const options = {
      hostname: projectApiHost,
      port: 443,
      path: path,
      method: "PUT", // Use PUT to replace the config
      headers: {
         "Authorization": `Bearer ${token}`,
         "Content-Type": "application/json",
         "Accept": "application/json",
         "If-Match": etag // Required header for concurrency control
      },
   };
   const requestBody = JSON.stringify(configData);
   console.log(`Updating config at: ${options.hostname}${options.path} with ETag: ${etag}`);
   const response = await makeRequest(options, requestBody);

   if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        console.log("Successfully updated config.");
        return JSON.parse(response.body); // Return the updated config
      } catch (e) {
        throw new Error("Failed to parse Project Config PUT response");
      }
   } else {
        // Log detailed error for PUT failure
        console.error(`Project Config PUT request failed (${response.statusCode}): ${response.body}`);
        console.error(`Request Body Sent: ${requestBody.substring(0, 500)}...`); // Log part of the body
        throw new Error(`Project Config PUT request failed (${response.statusCode}): ${response.body}`);
   }
}


// --- Main Function Logic ---
exports.main = async (params) => {
  console.log("Function execution started.");
  const apiKey = process.env.PROJECT_API_KEY;
  const projectId = process.env.PROJECT_ID;
  const configId = process.env.CONFIG_ID;
  const region = process.env.REGION || 'us-south'; // Get region from env var

  if (!apiKey || !projectId || !configId) {
    console.error("Missing required environment variables.");
    return {
      statusCode: 400,
      headers: { "content-type": "text/plain" },
      body: "Configuration Error: Missing PROJECT_API_KEY, PROJECT_ID, or CONFIG_ID in environment variables."
    };
  }
  console.log(`Using ProjectID: ${projectId}, ConfigID: ${configId}, Region: ${region}`);

  try {
    // 1. Get IAM Bearer Token
    console.log("Attempting to get IAM token...");
    const iamToken = await getIAMToken(apiKey);
    if (!iamToken) {
        // This case should be handled by getIAMToken throwing an error
        console.error("IAM token was unexpectedly null or empty.");
        throw new Error("Failed to retrieve IAM token.");
    }
    console.log("IAM token obtained successfully.");

    // 2. Get the current Project Configuration and its ETag
    console.log("Attempting to get project config...");
    const { config: currentConfig, etag } = await getProjectConfig(projectId, configId, iamToken);
    if (!etag) {
        console.error("Missing ETag header in GET response.");
        throw new Error("Missing ETag from GET config response. Cannot safely update.");
    }
    console.log(`Obtained config with ETag: ${etag}`);

    // 3. --- Stage an Update ---
    console.log("Staging update to config description...");
    const updateTimestamp = new Date().toISOString();
    let newDescription = currentConfig.description || "";
    // Remove old timestamp if present using regex
    newDescription = newDescription.replace(/\(Updated via Vibe Func: [^)]+\)/g, "").trim();
    // Add new timestamp
    currentConfig.description = `${newDescription} (Updated via Vibe Func: ${updateTimestamp})`;
    console.log(`New description: ${currentConfig.description}`);

    // Example: Modify an input variable (uncomment and adapt if needed)
    // currentConfig.inputs = currentConfig.inputs || {};
    // currentConfig.inputs.region = "eu-gb"; // Example change
    // console.log("Staged change to input variable 'region'");


    // 4. Save the modified configuration back using PUT and the ETag
    console.log("Attempting to update project config...");
    const updatedConfig = await updateProjectConfig(projectId, configId, iamToken, currentConfig, etag);
    console.log("Project config updated successfully via API.");

    // 5. Construct the Review URL
    const reviewUrl = `https://cloud.ibm.com/projects/${projectId}/configurations/${configId}/edit?region=${region}`;
    console.log(`Review URL constructed: ${reviewUrl}`);

    console.log("Function execution completed successfully.");
    return {
      statusCode: 200,
      headers: { "content-type": "text/plain" },
      body: `✅ Configuration staged successfully!\n\nReview changes at:\n${reviewUrl}\n\nTimestamp added: ${updateTimestamp}`
    };

  } catch (error) {
    // Log the detailed error
    console.error("Error during function execution:", error.stack || error.message);
    return {
      statusCode: 500,
      headers: { "content-type": "text/plain" },
      // Provide a more user-friendly error in the body, log details for debugging
      body: `❌ Error staging project configuration. Please check function logs for details. Message: ${error.message}`
    };
  }
};