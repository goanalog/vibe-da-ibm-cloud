/**
 * IBM Cloud Function to receive HTML content and push it to a COS bucket.
 */
const { S3 } = require('@ibm-cloud/object-storage');

async function main(params) {
  // 1. Get parameters passed from Terraform
  const { BUCKET_NAME, COS_ENDPOINT, COS_INSTANCE_ID } = params;

  // 2. Get credentials from the Service Binding (in process.env)
  //    This is the new part. The binding injects a JSON string.
  let cosCredentials;
  try {
    // The key '__OW_SERVICE_CREDENTIALS' holds the bound service JSON
    const creds = JSON.parse(process.env.__OW_SERVICE_CREDENTIALS);
    // Find our COS binding (we only have one)
    cosCredentials = creds[Object.keys(creds)[0]];
    if (!cosCredentials.apikey) throw new Error();
  } catch (e) {
    return {
      statusCode: 500,
      body: { error: 'Failed to parse service credentials from binding.' }
    };
  }

  // 3. Get the HTML content from the request body
  const htmlContent = params.content;
  const objectKey = params.key || 'index.html'; 

  if (!htmlContent) {
    return {
      statusCode: 400,
      body: { error: 'No "content" field in request body.' }
    };
  }

  // 4. Set up the COS client
  const s3Client = new S3({
    endpoint: COS_ENDPOINT,
    // --- THIS IS THE FIX ---
    // Use the API key and CRN from the credentials we just parsed
    apiKeyId: cosCredentials.apikey, 
    serviceInstanceId: cosCredentials.resource_instance_id,
    // --- END FIX ---
    s3ForcePathStyle: true,
    signatureVersion: 'v4',
  });

  // 5. Try to upload the file
  try {
    console.log(`Uploading ${objectKey} to bucket ${BUCKET_NAME}...`);
    
    const putObjectResult = await s3Client.putObject({
      Bucket: BUCKET_NAME,
      Key: objectKey,
      Body: htmlContent,
      ContentType: 'text/html',
    }).promise();

    console.log('Upload successful.');

    // 6. Send a success response back to the IDE
    return {
      statusCode: 200,
      body: {
        message: 'Vibe shipped to COS! 🚀',
        bucket: BUCKET_NAME,
        key: objectKey,
        etag: putObjectResult.ETag
      }
    };
  } catch (e) {
    console.error('Upload failed:', e);
    // 7. Send an error response
    return {
      statusCode: 500,
      body: { error: `Failed to put object in bucket: ${e.message}` }
    };
  }
}

module.exports.main = main;