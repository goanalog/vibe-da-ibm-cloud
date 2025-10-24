/**
 * IBM Cloud Code Engine (Node.js 18) — push_to_cos
 * Expects env vars: COS_ENDPOINT, COS_BUCKET, COS_REGION, ACCESS_KEY_ID, SECRET_ACCESS_KEY
 * Writes a tiny marker file to the bucket to prove write access works.
 */
const crypto = require("crypto");
const https = require("https");

function s3Put({ endpoint, region, bucket, key, body, accessKey, secretKey }) {
  // Minimal S3 SigV4 for IBM COS (virtual-hosted style URL not required here)
  const host = new URL(endpoint).host;
  const now = new Date();
  const amzDate = now.toISOString().replace(/[:-]|\.\d{3}/g, "") + "Z";
  const dateStamp = amzDate.slice(0, 8);
  const path = `/${bucket}/${encodeURIComponent(key)}`;
  const payload = Buffer.from(body);
  const payloadHash = crypto.createHash("sha256").update(payload).digest("hex");
  const canonicalHeaders =
    `host:${host}\n` +
    `x-amz-content-sha256:${payloadHash}\n` +
    `x-amz-date:${amzDate}\n`;
  const signedHeaders = "host;x-amz-content-sha256;x-amz-date";
  const canonicalRequest =
    `PUT\n${path}\n\n${canonicalHeaders}\n${signedHeaders}\n${payloadHash}`;

  const algorithm = "AWS4-HMAC-SHA256";
  const credentialScope = `${dateStamp}/${region}/s3/aws4_request`;
  const stringToSign =
    `${algorithm}\n${amzDate}\n${credentialScope}\n` +
    crypto.createHash("sha256").update(canonicalRequest).digest("hex");

  const kDate = crypto.createHmac("sha256", "AWS4" + secretKey).update(dateStamp).digest();
  const kRegion = crypto.createHmac("sha256", kDate).update(region).digest();
  const kService = crypto.createHmac("sha256", kRegion).update("s3").digest();
  const kSigning = crypto.createHmac("sha256", kService).update("aws4_request").digest();
  const signature = crypto.createHmac("sha256", kSigning).update(stringToSign).digest("hex");
  const authorization =
    `${algorithm} Credential=${accessKey}/${credentialScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`;

  const options = {
    host,
    method: "PUT",
    path,
    headers: {
      "Authorization": authorization,
      "x-amz-date": amzDate,
      "x-amz-content-sha256": payloadHash,
      "Content-Length": payload.length
    }
  };
  return new Promise((resolve, reject) => {
    const req = https.request(options, res => {
      let data = "";
      res.on("data", d => (data += d));
      res.on("end", () => {
        if (res.statusCode >= 200 && res.statusCode < 300) resolve({ statusCode: res.statusCode, body: data || "OK" });
        else reject(new Error(`COS PUT failed ${res.statusCode}: ${data}`));
      });
    });
    req.on("error", reject);
    req.write(payload);
    req.end();
  });
}

exports.main = async (params) => {
  // Read from secure environment variables (injected by Code Engine secrets)
  const endpoint = process.env.COS_ENDPOINT;
  const bucket   = process.env.COS_BUCKET;
  const region   = process.env.COS_REGION;
  const access   = process.env.ACCESS_KEY_ID;
  const secret   = process.env.SECRET_ACCESS_KEY;

  if(!endpoint || !bucket || !region || !access || !secret){
     console.error("Missing required COS environment variables");
     return { statusCode: 400, body: "Configuration Error: Missing required COS environment variables." };
  }

  const key  = `vibe-writecheck-${Date.now()}.txt`;
  const body = `max-vibe OK @ ${new Date().toISOString()}\n`;
  try {
    const result = await s3Put({
      endpoint,
      region,
      bucket,
      key,
      body,
      accessKey: access,
      secretKey: secret
    });
    console.log(`Successfully wrote ${key} to ${bucket}`);
    return { statusCode: result.statusCode, body: `Wrote ${key} to ${bucket}` };
  } catch (e) {
    console.error(`Error writing to COS: ${e.message}`);
    return { statusCode: 500, body: `Error writing to COS: ${e.message}` };
  }
};