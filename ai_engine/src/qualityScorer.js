const { getShelfLifeDays } = require('./shelfLifeTable');

/**
 * Rule-based spoilage/quality scoring.
 *
 * Logic:
 *  1. Look up typical ambient shelf life for the crop.
 *  2. Refrigerated storage effectively doubles usable shelf life (rough
 *     rule of thumb, not crop-specific in this version).
 *  3. Quality score decays roughly linearly from 100 (freshly harvested) to
 *     0 (at end of shelf life), then floors at 0 past that point.
 *  4. Spoilage risk bucket derived from the score, with a recommended
 *     action a farmer/buyer could act on.
 *
 * This does NOT use any sensor/IoT input (that's Yogaprakash/Harsha's
 * hardware work - weight sensor, RFID/freshness sensor). This is a
 * time-based estimate only, meant as a fallback/baseline until real sensor
 * data can feed into a more accurate model.
 */
function scoreQuality({ cropName, daysSinceHarvest, storageCondition }) {
  const shelfLifeDays = getShelfLifeDays(cropName);
  const effectiveShelfLife =
    storageCondition === 'refrigerated' ? shelfLifeDays * 2 : shelfLifeDays;

  const daysElapsed = Math.max(0, Number(daysSinceHarvest) || 0);
  const remainingFraction = Math.max(0, 1 - daysElapsed / effectiveShelfLife);
  const qualityScore = Math.round(remainingFraction * 100);

  let spoilageRisk;
  let recommendedAction;
  if (qualityScore >= 70) {
    spoilageRisk = 'low';
    recommendedAction = 'Safe to list and sell normally.';
  } else if (qualityScore >= 40) {
    spoilageRisk = 'medium';
    recommendedAction = 'Prioritize this batch for sale soon; consider a small price reduction to move it faster.';
  } else if (qualityScore > 0) {
    spoilageRisk = 'high';
    recommendedAction = 'Sell immediately or divert to processing/discount channel; spoilage risk is significant.';
  } else {
    spoilageRisk = 'critical';
    recommendedAction = 'Likely past usable shelf life - inspect before listing; may not be sellable as fresh produce.';
  }

  const estimatedDaysRemaining = Math.max(0, Math.round(effectiveShelfLife - daysElapsed));

  return { qualityScore, spoilageRisk, estimatedDaysRemaining, recommendedAction };
}

module.exports = { scoreQuality };
