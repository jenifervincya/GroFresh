require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { estimateFairPrice } = require('./estimator');
const { scoreQuality } = require('./qualityScorer');
const { evaluateBid } = require('./negotiationAgent');
const { analyzePriceFormation } = require('./priceAutopsy');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => res.json({ status: 'ok' }));

// POST /estimate
// Contract confirmed against the backend's src/services/pricing.service.js:
// { cropName, quantityKg } -> { fairPriceMin, fairPriceMax }
// No batchId in the request - the backend attaches that itself afterward.
app.post('/estimate', (req, res) => {
  const { cropName, quantityKg } = req.body;

  if (!cropName || typeof quantityKg !== 'number') {
    return res.status(400).json({ error: 'cropName (string) and quantityKg (number) are required' });
  }

  const { fairPriceMin, fairPriceMax } = estimateFairPrice({ cropName, quantityKg });
  return res.json({ fairPriceMin, fairPriceMax });
});

// POST /quality-score
// { cropName, daysSinceHarvest, storageCondition? } -> { qualityScore, spoilageRisk, estimatedDaysRemaining, recommendedAction }
// storageCondition is optional: 'ambient' (default) or 'refrigerated'.
// Time-based estimate only - no sensor input. Real freshness sensor data
// from Yogaprakash/Harsha's hardware work would be a better future input
// but isn't wired in here.
app.post('/quality-score', (req, res) => {
  const { cropName, daysSinceHarvest, storageCondition } = req.body;

  if (!cropName || typeof daysSinceHarvest !== 'number') {
    return res.status(400).json({ error: 'cropName (string) and daysSinceHarvest (number) are required' });
  }
  if (storageCondition && !['ambient', 'refrigerated'].includes(storageCondition)) {
    return res.status(400).json({ error: "storageCondition must be 'ambient' or 'refrigerated' if provided" });
  }

  const result = scoreQuality({ cropName, daysSinceHarvest, storageCondition });
  return res.json(result);
});

// POST /negotiate
// { fairPriceMin, fairPriceMax, currentBidPrice } -> { recommendation, suggestedCounterPrice, reasoning }
// recommendation is one of 'accept' | 'counter' | 'reject'.
app.post('/negotiate', (req, res) => {
  const { fairPriceMin, fairPriceMax, currentBidPrice } = req.body;

  if (
    typeof fairPriceMin !== 'number' ||
    typeof fairPriceMax !== 'number' ||
    typeof currentBidPrice !== 'number'
  ) {
    return res.status(400).json({
      error: 'fairPriceMin, fairPriceMax, and currentBidPrice must all be numbers',
    });
  }

  try {
    const result = evaluateBid({ fairPriceMin, fairPriceMax, currentBidPrice });
    return res.json(result);
  } catch (err) {
    return res.status(400).json({ error: err.message });
  }
});

// POST /price-autopsy
// { fairPriceMin, fairPriceMax, priceHistory: [{ price, label, time }] }
// -> { summary, steps, finalPrice, totalMovement, fairPriceMin, fairPriceMax, bandPosition, percentOfFairBand }
// Narrates an already-recorded price history (the same shape the backend's
// batch model stores/returns) rather than deriving prices itself.
app.post('/price-autopsy', (req, res) => {
  const { fairPriceMin, fairPriceMax, priceHistory } = req.body;

  if (typeof fairPriceMin !== 'number' || typeof fairPriceMax !== 'number') {
    return res.status(400).json({ error: 'fairPriceMin and fairPriceMax must both be numbers' });
  }
  if (!Array.isArray(priceHistory) || priceHistory.length === 0) {
    return res.status(400).json({ error: 'priceHistory must be a non-empty array of { price, label, time }' });
  }

  try {
    const result = analyzePriceFormation({ fairPriceMin, fairPriceMax, priceHistory });
    return res.json(result);
  } catch (err) {
    return res.status(400).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`GroFresh AI engines service listening on port ${PORT}`);
});
