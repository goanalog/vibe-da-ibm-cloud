// IBM Cloud Functions web action that returns a presigned PUT URL for index.html.
// Uses AWS S3-compatible SDK against IBM COS (Lite-friendly).
// Public-read is enforced via ACL in the signed request (only on explicit user click).

const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

async function main(params) {
  const {
    COS_ACCESS_KEY_ID,
    COS_SECRET_ACCESS_KEY,
    BUCKET,
    REGION = "us-south",
    filename = "index.html",
    contentType = "text/html"
  } = params;

  if (!COS_ACCESS_KEY_ID || !COS_SECRET_ACCESS_KEY || !BUCKET) {
    return { statusCode: 500, headers: cors(), body: JSON.stringify({ error: "Missing COS credentials or bucket." }) };
  }

  const s3 = new S3Client({
    endpoint: `https://s3.${REGION}.cloud-object-storage.appdomain.cloud`,
    region: REGION,
    credentials: { accessKeyId: COS_ACCESS_KEY_ID, secretAccessKey: COS_SECRET_ACCESS_KEY }
  });

  // Make new uploads publicly readable
  const command = new PutObjectCommand({ Bucket: BUCKET, Key: filename, ContentType: contentType, ACL: "public-read" });
  const signedUrl = await getSignedUrl(s3, command, { expiresIn: 300 });
  const publicUrl = `https://${BUCKET}.s3.${REGION}.cloud-object-storage.appdomain.cloud/${filename}`;

  return { statusCode: 200, headers: cors(), body: JSON.stringify({ signedUrl, publicUrl }) };
}

function cors() {
  return {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization"
  };
}

exports.main = main;
