const express = require('express');
const batchController = require('../controllers/batch.controller');
const trackingController = require('../controllers/tracking.controller');
const chatController = require('../controllers/chat.controller');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.use(requireAuth); // every /batches route requires login, per Tamil's assumption

router.get('/', batchController.listNearby);
router.get('/:batchId', batchController.getById);
router.post('/', batchController.create);
router.post('/:batchId/bids', batchController.placeBid);
router.post('/:batchId/bids/:bidId/accept', batchController.acceptBid);

router.get('/:batchId/tracking', trackingController.getTracking);
router.post('/:batchId/delivery/generate-otp', trackingController.generateDeliveryOtp);
router.post('/:batchId/delivery/verify-otp', trackingController.verifyDeliveryOtp);

router.get('/:batchId/messages', chatController.listMessages);
router.post('/:batchId/messages', chatController.postMessage);

module.exports = router;
