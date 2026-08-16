const kycModel = require('../models/kyc.model');
const uploadService = require('../services/upload.service');

// POST /kyc/upload-url
// Not in Tamil's original doc as a separate call (she assumed multipart on
// /kyc/submit) - added because the Q4 decision was pre-signed URLs, which
// needs a step to issue the URL before the actual submit call.
async function getUploadUrl(req, res) {
  const target = uploadService.createUploadTarget('kyc');
  return res.status(200).json(target);
}

// POST /kyc/submit
// { userId, idType, idNumber, documentObjectKey } -> 200 OK
async function submit(req, res) {
  const { idType, idNumber, documentObjectKey } = req.body;
  if (!idType || !idNumber || !documentObjectKey) {
    return res.status(400).json({ error: 'idType, idNumber, and documentObjectKey are required' });
  }

  await kycModel.submit({
    userId: req.userId,
    idType,
    idNumber,
    documentObjectKey,
  });

  return res.status(200).end();
}

module.exports = { getUploadUrl, submit };
