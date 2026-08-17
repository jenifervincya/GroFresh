/**
 * Rule-based "price autopsy" / price-formation analysis.
 *
 * Maps to the pitch doc's "Price Journey Transparency" feature and Neha's
 * "price autopsy module" ownership: given a batch's price history (the
 * same priceHistory array already stored/returned by the backend's batch
 * model - Listed, Bid placed, Bid accepted, etc.) and its fair-price band,
 * produce a plain-language breakdown of how the final price was formed and
 * how it compares to fair value.
 *
 * This does NOT re-derive the price - it takes the already-recorded
 * history as input and narrates it. The backend remains the source of
 * truth for what actually happened; this only explains it.
 */
function analyzePriceFormation({ fairPriceMin, fairPriceMax, priceHistory }) {
  if (!Array.isArray(priceHistory) || priceHistory.length === 0) {
    throw new Error('priceHistory must be a non-empty array of { price, label, time }');
  }

  const listed = priceHistory[0];
  const final = priceHistory[priceHistory.length - 1];
  const fairMid = (fairPriceMin + fairPriceMax) / 2;

  const steps = priceHistory.map((entry, i) => {
    const prev = i > 0 ? priceHistory[i - 1] : null;
    const delta = prev ? Math.round((entry.price - prev.price) * 100) / 100 : 0;
    return {
      label: entry.label,
      price: entry.price,
      time: entry.time,
      changeFromPrevious: delta,
    };
  });

  const totalMovement = Math.round((final.price - listed.price) * 100) / 100;
  const percentOfFairBand =
    fairPriceMax > fairPriceMin
      ? Math.round(((final.price - fairPriceMin) / (fairPriceMax - fairPriceMin)) * 100)
      : null;

  let bandPosition;
  if (final.price < fairPriceMin) bandPosition = 'below fair range';
  else if (final.price > fairPriceMax) bandPosition = 'above fair range';
  else if (final.price >= fairMid) bandPosition = 'upper half of fair range';
  else bandPosition = 'lower half of fair range';

  const summary = buildSummary({ listed, final, totalMovement, bandPosition, fairPriceMin, fairPriceMax });

  return {
    summary,
    steps,
    finalPrice: final.price,
    totalMovement,
    fairPriceMin,
    fairPriceMax,
    bandPosition,
    percentOfFairBand, // null if fairPriceMin === fairPriceMax; otherwise 0-100+ (can exceed 100 if above band)
  };
}

function buildSummary({ listed, final, totalMovement, bandPosition, fairPriceMin, fairPriceMax }) {
  const direction = totalMovement > 0 ? 'rose' : totalMovement < 0 ? 'fell' : 'stayed flat';
  const movementPhrase =
    totalMovement === 0
      ? `remained at Rs.${listed.price} from listing to final price`
      : `${direction} from Rs.${listed.price} to Rs.${final.price} (${totalMovement > 0 ? '+' : ''}${totalMovement})`;

  const positionPhrase =
    bandPosition === 'below fair range' || bandPosition === 'above fair range'
      ? `falls ${bandPosition}`
      : `falls in the ${bandPosition}`;

  return `Price ${movementPhrase} through ${final.label.toLowerCase()}. Final price of Rs.${final.price} ${positionPhrase} (fair band: Rs.${fairPriceMin}-Rs.${fairPriceMax}).`;
}

module.exports = { analyzePriceFormation };
