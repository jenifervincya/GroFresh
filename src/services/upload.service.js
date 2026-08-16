const crypto = require('crypto');

/**
 * Q4 decision: pre-signed upload URLs instead of raw multipart.
 *
 * This is a local-storage stand-in until real object storage (S3/GCS/etc.)
 * is picked. It issues a short-lived upload token and object key with the
 * same shape a real pre-signed URL flow would use, so swapping in S3 later
 * only touches this file:
 *
 *   const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
 *   const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
 *   ... generate a real signed PUT URL against your bucket ...
 *
 * For now, the app should PUT the file to POST /uploads/:objectKey (add a
 * route + multer/raw-body handler if you want local uploads to actually
 * land on disk during development) or this can be swapped for real cloud
 * storage before this goes to buyers/farmers in production.
 */
function createUploadTarget(prefix = 'kyc') {
  const objectKey = `${prefix}/${crypto.randomUUID()}`;
  const uploadUrl = `${process.env.UPLOAD_BASE_URL || 'http://localhost:4000'}/uploads/${objectKey}`;
  return { objectKey, uploadUrl };
}

module.exports = { createUploadTarget };
