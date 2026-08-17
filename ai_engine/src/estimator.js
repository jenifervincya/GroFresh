const { getBasePrice } = require('./priceTable');

/**
 * Rule-based fair-price band estimator.
 *
 * Logic (deliberately simple for a hackathon demo, not a trained model):
 *  1. Look up a base Rs/kg for the crop (see priceTable.js).
 *  2. Apply a bulk-quantity discount to the base price - larger batches
 *     typically negotiate a slightly lower per-kg rate in real mandi
 *     trading, so a 500kg batch shouldn't get the same per-kg estimate as
 *     a 5kg one.
 *  3. Return a symmetric-ish band around that adjusted base: min is 12%
 *     below, max is 15% above (deliberately asymmetric - farmers should see
 *     more upside than downside in the suggested band, since the fair-price
 *     tool is meant to protect against being lowballed, not to cap upside).
 *
 * This is intentionally isolated in one function so it can be replaced with
 * a real trained model later without touching server.js's request handling.
 */
function estimateFairPrice({ cropName, quantityKg }) {
  const basePrice = getBasePrice(cropName);

  const qty = Number(quantityKg) || 0;
  let bulkDiscount = 0;
  if (qty >= 500) bulkDiscount = 0.08;
  else if (qty >= 200) bulkDiscount = 0.05;
  else if (qty >= 50) bulkDiscount = 0.02;

  const adjustedBase = basePrice * (1 - bulkDiscount);

  const fairPriceMin = Math.round(adjustedBase * 0.88 * 100) / 100;
  const fairPriceMax = Math.round(adjustedBase * 1.15 * 100) / 100;

  return { fairPriceMin, fairPriceMax };
}

module.exports = { estimateFairPrice };
