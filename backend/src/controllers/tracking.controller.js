const trackingModel = require('../models/tracking.model');
const batchModel = require('../models/batch.model');
const otpService = require('../services/otp.service');
const escrowService = require('../services/escrow.service');
const smsService = require('../services/sms.service');

// GET /batches/:batchId/tracking
async function getTracking(req, res) {
  const batch = await batchModel.getById(req.params.batchId);
  if (!batch) return res.status(404).json({ error: 'batch not found' });

  const tracking = await trackingModel.getTracking(req.params.batchId);
  return res.json(tracking);
}

// POST /batches/:batchId/delivery/verify-otp
// This is the trigger for EscrowService's PAYMENT_RELEASED event.
// Q6 decision: response includes the updated tracking steps directly.
async function verifyDeliveryOtp(req, res) {
  const { otp } = req.body;
  const { batchId } = req.params;

  if (!otp) {
    return res.status(400).json({ error: 'otp is required' });
  }

  const batch = await batchModel.getById(batchId);
  if (!batch) return res.status(404).json({ error: 'batch not found' });

  // Delivery OTPs are scoped by batchId as the "phone" key for this purpose,
  // since they're not tied to a phone number but to a specific batch/order.
  const isValid = await otpService.verifyOtp(batchId, otp, 'delivery');
  if (!isValid) {
    return res.status(401).json({ success: false, error: 'invalid or expired OTP' });
  }

  await trackingModel.markStepComplete(batchId, 'Delivered');
  await escrowService.releasePaymentOnDelivery(batchId);
  await trackingModel.markStepComplete(batchId, 'Paid');

  // Fire delivery-confirmed notification. Swap to automatic server-side
  // dispatch instead once Q7 is confirmed with Tamil.
  const contacts = await batchModel.getContactPhones(batchId);
  if (contacts?.sellerPhone) {
    await smsService.sendSms(contacts.sellerPhone, `Payment released for batch ${batch.cropName} - delivery confirmed.`);
  }

  const tracking = await trackingModel.getTracking(batchId);
  return res.status(200).json({ success: true, tracking });
}

// POST /batches/:batchId/delivery/generate-otp
// Not in Tamil's original doc - added because something has to generate the
// delivery OTP before it can be verified. Currently callable by the seller
// once the batch ships; long-term this is probably triggered by the IoT
// tracker (Archana/Yogaprakash) hitting "picked up", not a manual app call.
// Flag this to Tamil/Archana before relying on it long-term.
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
