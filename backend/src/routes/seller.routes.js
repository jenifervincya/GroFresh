const express = require('express');
const batchController = require('../controllers/batch.controller');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.use(requireAuth);

router.get('/:sellerId/batches', batchController.listBySeller);

module.exports = router;
