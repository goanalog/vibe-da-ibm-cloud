/**
 * Vibe COS presign endpoint (Node.js)
 * NOTE: This is provided for completeness; the Terraform block that deploys
 * this action is disabled by default behind `enable_functions` to avoid schema
 * drift across provider versions. Enable by setting -var enable_functions=true.
 */
async function main(params) {
  return {
    statusCode: 200,
    headers: { "content-type": "application/json" },
    body: {
      ok: true,
      note: "Stub action: wire your COS HMAC to generate presigned URLs here."
    }
  };
}
