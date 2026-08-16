const express = require('express');
const { requireAuth } = require('../middleware/auth');
const userModel = require('../models/user.model');
const smsService = require('../services/sms.service');

const router = express.Router();
router.use(requireAuth);

// Simple template registry. Real templates/copy live with Tamil per the
// Farmora team doc (she owns multilingual SMS/IVR templates) - this just
// renders params into a template string per language.
const TEMPLATES = {
  en: {
    bid_received: (p) => `New bid of Rs.${p.amount} received on your batch.`,
    delivery_confirmed: (p) => `Delivery confirmed for batch ${p.cropName}. Payment released.`,
  },
  hi: {
    bid_received: (p) => `Aapke batch par Rs.${p.amount} ki nai bid mili hai.`,
    delivery_confirmed: (p) => `Batch ${p.cropName} ki delivery confirm ho gayi. Payment release ho gaya.`,
  },
  ta: {
    bid_received: (p) => `Unga batch-ku Rs.${p.amount} pudhu bid kidaichirukku.`,
    delivery_confirmed: (p) => `Batch ${p.cropName} delivery confirm aachu. Payment release aayiduchu.`,
  },
};

// POST /notifications/trigger
// { userId, templateKey, language, params } -> 200 OK
// Q7: built as app-triggered per the reply sent to Tamil. If SMS/IVR turns
// out to be automatic server-side instead, this route becomes redundant -
// keep the TEMPLATES object either way since it'll be reused internally.
router.post('/trigger', async (req, res) => {
  const { userId, templateKey, language, params } = req.body;
  if (!userId || !templateKey) {
    return res.status(400).json({ error: 'userId and templateKey are required' });
  }

  const user = await userModel.findById(userId);
  if (!user) return res.status(404).json({ error: 'user not found' });

  const lang = TEMPLATES[language] ? language : 'en';
  const templateFn = TEMPLATES[lang][templateKey];
  if (!templateFn) {
    return res.status(400).json({ error: `unknown templateKey: ${templateKey}` });
  }

  const message = templateFn(params || {});
  await smsService.sendSms(user.phone, message);

  return res.status(200).end();
});

module.exports = router;
