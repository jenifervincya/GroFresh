const batchModel = require('../models/batch.model');
const pricingService = require('../services/pricing.service');
const notificationService = require('../services/notification.service');

async function listNearby(req, res) {
  const lat = req.query.lat ? parseFloat(req.query.lat) : null;
  const lng = req.query.lng ? parseFloat(req.query.lng) : null;
  const batches = await batchModel.listNearby(lat, lng);
  return res.json(batches);
}

async function getById(req, res) {
  const batch = await batchModel.getById(req.params.batchId);
  if (!batch) return res.status(404).json({ error: 'batch not found' });
  return res.json(batch);
}

async function listBySeller(req, res) {
  const batches = await batchModel.listBySeller(req.params.sellerId);
  return res.json(batches);
}

async function create(req, res) {
  const { cropName, quantityKg, imageUrl } = req.body;
  if (!cropName || !quantityKg) {
    return res.status(400).json({ error: 'cropName and quantityKg are required' });
  }

  const { fairPriceMin, fairPriceMax } = await pricingService.estimateFairPrice({
    cropName,
    quantityKg,
  });

  const batch = await batchModel.create({
    cropName,
    quantityKg,
    sellerId: req.userId,
    imageUrl,
    fairPriceMin,
    fairPriceMax,
  });

  return res.status(201).json(batch);
}

async function placeBid(req, res) {
  const { amount } = req.body;
  if (typeof amount !== 'number') {
    return res.status(400).json({ error: 'amount must be a number' });
  }

  const batch = await batchModel.getById(req.params.batchId);
  if (!batch) return res.status(404).json({ error: 'batch not found' });

  await batchModel.placeBid(req.params.batchId, req.userId, amount);

  await notificationService.send({
    userId: batch.sellerId,
    templateKey: 'bid_received',
    params: { amount },
  });

  return res.status(200).end();
}

async function acceptBid(req, res) {
  const updated = await batchModel.acceptBid(req.params.batchId, req.params.bidId);
  if (!updated) return res.status(404).json({ error: 'bid not found for this batch' });

  await notificationService.send({
    userId: updated.buyerId,
    templateKey: 'auction_won',
    params: { cropName: updated.cropName, amount: updated.currentBidPrice },
  });

  await notificationService.send({
    userId: updated.sellerId,
    templateKey: 'sale_confirmed',
    params: { cropName: updated.cropName, amount: updated.currentBidPrice },
  });

  return res.status(200).end();
}

module.exports = { listNearby, getById, listBySeller, create, placeBid, acceptBid };
