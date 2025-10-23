/**
 * IBM Cloud Function to receive HTML content and push it to a COS bucket.
 */
const { S3 } = require('@ibm-cloud/object-storage');

async function main(params) {
  // 1. Get parameters passed from Terraform
  const { BUCKET_NAME, COS_ENDPOINT, COS_INSTANCE_ID } = process.env;

  // 2. Get the HTML content from the request body
  const htmlContent = params.content;
  const objectKey = params.key || 'index.html'; 

  if (!htmlContent) {
    return {
      statusCode: 400,
      body: { error: 'No "content" field in request body.' }
    };
  }

  // 3. Set up the COS client
  const s3Client = new S3({
    endpoint: COS_ENDPOINT,
    s3ForcePathStyle: true,
    signatureVersion: 'v4',
  });

  // 4. Try to upload the file
  try {
    console.log(`Uploading ${objectKey} to bucket ${BUCKET_NAME}...`);
    
    const putObjectResult = await s3Client.putObject({
      Bucket: BUCKET_NAME,
      Key: objectKey,
      Body: htmlContent,
      ContentType: 'text/html',
      // The 'ACL: "public-read"' line has been REMOVED
    }).promise();

    console.log('Upload successful.');

    // 5. Send a success response back to the IDE
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
    // 6. Send an error response
    return {
      statusCode: 500,
      body: { error: `Failed to put object in bucket: ${e.message}` }
    };
  }
}

module.exports.main = main;