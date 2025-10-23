
/**
 * Functional push_to_cos action — uploads `index.html` to IBM COS via S3 API.
 * Requires HMAC credentials and region/endpoint passed by Terraform parameters.
 */
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");

async function main(params) {
  const {
    bucket_name,
    html_input,
    cos_endpoint,
    cos_region,
    hmac_access_key_id,
    hmac_secret_access_key,
    key_name = "index.html",
  } = params;

  if (!bucket_name) return { statusCode: 400, body: "missing bucket_name" };
  if (!hmac_access_key_id || !hmac_secret_access_key) {
    return { statusCode: 500, body: "missing HMAC credentials" };
  }
  const endpoint = cos_endpoint || `https://s3.${cos_region}.cloud-object-storage.appdomain.cloud`;
  const client = new S3Client({
    endpoint,
    region: cos_region,
    forcePathStyle: true,
    credentials: {
      accessKeyId: hmac_access_key_id,
      secretAccessKey: hmac_secret_access_key,
    },
  });

  const body = html_input || "<!doctype html><meta charset='utf-8'><title>Empty</title><h1>No HTML provided</h1>";
  await client.send(new PutObjectCommand({
    Bucket: bucket_name,
    Key: key_name,
    Body: body,
    ContentType: "text/html; charset=utf-8",
    ACL: "public-read"
  }));

  return {
    statusCode: 200,
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      ok: true,
      bucket: bucket_name,
      key: key_name,
      size: (body || "").length,
      url: `https://s3.${cos_region}.cloud-object-storage.appdomain.cloud/${bucket_name}/${key_name}`
    }),
  };
}
exports.main = main;
