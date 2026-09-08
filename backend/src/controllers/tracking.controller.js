const trackingModel = require('../models/tracking.model');
const batchModel = require('../models/batch.model');
const otpService = require('../services/otp.service');
const escrowService = require('../services/escrow.service');
const smsService = require('../services/sms.service');
const notificationService = require('../services/notification.service');

async function getTracking(req, res) {
  const batch = await batchModel.getById(req.params.batchId);
  if (!batch) return res.status(404).json({ error: 'batch not found' });

  const tracking = await trackingModel.getTracking(req.params.batchId);
  return res.json(tracking);
}

async function verifyDeliveryOtp(req, res) {
  const { otp } = req.body;
  const { batchId } = req.params;

  if (!otp) {
    return res.status(400).json({ error: 'otp is required' });
  }

  const batch = await batchModel.getById(batchId);
  if (!batch) return res.status(404).json({ error: 'batch not found' });

  const isValid = await otpService.verifyOtp(batchId, otp, 'delivery');
  if (!isValid) {
    return res.status(401).json({ success: false, error: 'invalid or expired OTP' });
  }

  await trackingModel.markStepComplete(batchId, 'Delivered');
  await escrowService.releasePaymentOnDelivery(batchId);
  await trackingModel.markStepComplete(batchId, 'Paid');

  const contacts = await batchModel.getContactPhones(batchId);
  if (contacts?.sellerPhone) {
    await smsService.sendSms(contacts.sellerPhone, `Payment released for batch ${batch.cropName} - delivery confirmed.`);
  }

  await notificationService.send({
    userId: batch.sellerId,
    templateKey: 'payment_released',
    params: { cropName: batch.cropName, amount: batch.currentBidPrice },
  });

  const tracking = await trackingModel.getTracking(batchId);
  return res.status(200).json({ success: true, tracking });
}

async function generateDeliveryOtp(req, res) {
  const { batchId } = req.params;
  const batch = await batchModel.getById(batchId);
  if (!batch) return res.status(404).json({ error: 'batch not found' });

  const code = await otpService.requestOtp(batchId, 'delivery');
  await trackingModel.markStepComplete(batchId, 'Picked up');
  await trackingModel.markStepComplete(batchId, 'In transit');

  const contacts = await batchModel.getContactPhones(batchId);
  if (contacts?.buyerPhone) {
    await smsService.sendSms(contacts.buyerPhone, `Your GroFresh delivery OTP is ${code}`);
  } else {
    console.log(`[Delivery OTP for batch ${batchId}]: ${code}`);
  }

  return res.status(200).end();
}

module.exports = { getTracking, verifyDeliveryOtp, generateDeliveryOtp };
