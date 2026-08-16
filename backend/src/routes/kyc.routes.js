const express = require('express');
const kycController = require('../controllers/kyc.controller');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.use(requireAuth);

router.post('/upload-url', kycController.getUploadUrl);
router.post('/submit', kycController.submit);

module.exports = router;
