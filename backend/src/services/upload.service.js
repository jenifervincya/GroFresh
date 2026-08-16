const crypto = require('crypto');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');

/**
 * Real S3 pre-signed upload URLs, replacing the local-storage stand-in.
 *
 * Requires in .env:
 *   AWS_REGION
 *   AWS_ACCESS_KEY_ID
 *   AWS_SECRET_ACCESS_KEY
 *   S3_BUCKET_NAME
 *
 * If those aren't set, falls back to the same local-URL stand-in as before
 * so local/demo runs without an AWS account still work - set
 * STORAGE_PROVIDER=s3 explicitly once real bucket credentials are in place.
 *
 * Flow: this issues a short-lived signed PUT URL. The Flutter app PUTs the
 * file directly to S3 using that URL (never touching our backend/server
 * with the raw file bytes), then calls POST /kyc/submit with the same
 * objectKey to record the metadata.
 */

const s3Enabled =
  process.env.STORAGE_PROVIDER === 's3' &&
  process.env.AWS_REGION &&
  process.env.AWS_ACCESS_KEY_ID &&
  process.env.AWS_SECRET_ACCESS_KEY &&
  process.env.S3_BUCKET_NAME;

let s3Client = null;
if (s3Enabled) {
  s3Client = new S3Client({
    region: process.env.AWS_REGION,
    credentials: {
      accessKeyId: process.env.AWS_ACCESS_KEY_ID,
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    },
  });
}

const UPLOAD_URL_TTL_SECONDS = 300; // 5 minutes to complete the PUT

async function createUploadTarget(prefix = 'kyc') {
  const objectKey = `${prefix}/${crypto.randomUUID()}`;

  if (!s3Enabled) {
    // Local-storage stand-in fallback, same as before real S3 was wired up.
    const uploadUrl = `${process.env.UPLOAD_BASE_URL || 'http://localhost:4000'}/uploads/${objectKey}`;
    return { objectKey, uploadUrl };
  }

  const command = new PutObjectCommand({
    Bucket: process.env.S3_BUCKET_NAME,
    Key: objectKey,
  });
  const uploadUrl = await getSignedUrl(s3Client, command, { expiresIn: UPLOAD_URL_TTL_SECONDS });

  return { objectKey, uploadUrl };
}

module.exports = { createUploadTarget };
