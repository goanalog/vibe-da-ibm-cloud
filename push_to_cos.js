/**
 * IBM Cloud Function: push_to_cos
 * Expects parameters injected via Terraform:
 *  - COS_BUCKET_NAME
 *  - COS_REGION
 *  - COS_HMAC_ACCESS_KEY
 *  - COS_HMAC_SECRET_KEY
 *
 * Body (optional): { key?: string, content?: string, contentType?: string }
 * Writes an object to the COS bucket. Defaults to "hello.txt".
 */
const AWS = require('aws-sdk'); // available in NodeJS actions

function s3Client({ region, accessKeyId, secretAccessKey }) {
  const endpoint = `https://s3.${region}.cloud-object-storage.appdomain.cloud`;
  return new AWS.S3({
    endpoint,
    accessKeyId,
    secretAccessKey,
    signatureVersion: 'v4',
    s3ForcePathStyle: true,
  });
}

exports.main = async (params) => {
  const {
    COS_BUCKET_NAME,
    COS_REGION,
    COS_HMAC_ACCESS_KEY,
    COS_HMAC_SECRET_KEY,
    key = 'hello.txt',
    content = `Hello from push_to_cos at ${new Date().toISOString()}\n`,
    contentType = 'text/plain'
  } = params;

  if (!COS_BUCKET_NAME || !COS_REGION || !COS_HMAC_ACCESS_KEY || !COS_HMAC_SECRET_KEY) {
    return { statusCode: 500, body: 'Missing COS credentials or config' };
  }

  const s3 = s3Client({
    region: COS_REGION,
    accessKeyId: COS_HMAC_ACCESS_KEY,
    secretAccessKey: COS_HMAC_SECRET_KEY
  });

  try {
    await s3.putObject({
      Bucket: COS_BUCKET_NAME,
      Key: key,
      Body: content,
      ContentType: contentType,
      ACL: 'public-read'
    }).promise();

    const publicUrl = `https://${COS_BUCKET_NAME}.s3.${COS_REGION}.cloud-object-storage.appdomain.cloud/${encodeURIComponent(key)}`;
    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ok: true, key, url: publicUrl })
    };
  } catch (err) {
    return { statusCode: 500, body: `Upload failed: ${err.message}` };
  }
};
