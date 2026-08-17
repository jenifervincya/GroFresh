/**
 * Rule-based negotiation agent.
 *
 * Given a batch's fair-price band and a buyer's current bid, suggests
 * whether the farmer should accept, counter, or reject - and if countering,
 * what price to counter at.
 *
 * Logic:
 *  - Bid at or above 95% of fairPriceMax -> accept (buyer's already paying
 *    close to the top of fair value, don't risk losing the sale by haggling
 *    further).
 *  - Bid within the fair band (>= fairPriceMin) -> counter partway between
 *    the bid and fairPriceMax, nudging toward a better price without
 *    scaring the buyer off with a big jump.
 *  - Bid below fairPriceMin but above 70% of it -> counter at fairPriceMin
 *    itself - still in reach of a deal, but hold the floor.
 *  - Bid below 70% of fairPriceMin -> reject outright; too far below fair
 *    value to be worth countering, likely to erode trust in the price
 *    signal if farmers accept lowball bids often.
 *
 * This has no memory of prior rounds in this version (each call is
 * stateless) - the caller (batch.controller.js, if wired in later) would
 * need to track bid history and re-call this per new bid.
 */
function evaluateBid({ fairPriceMin, fairPriceMax, currentBidPrice }) {
  if (
    typeof fairPriceMin !== 'number' ||
    typeof fairPriceMax !== 'number' ||
    typeof currentBidPrice !== 'number'
  ) {
    throw new Error('fairPriceMin, fairPriceMax, and currentBidPrice must all be numbers');
  }

  const acceptThreshold = fairPriceMax * 0.95;
  const rejectThreshold = fairPriceMin * 0.7;

  if (currentBidPrice >= acceptThreshold) {
    return {
      recommendation: 'accept',
      suggestedCounterPrice: null,
      reasoning: 'Bid is at or near the top of the fair-price band - accepting secures a strong price without risking the sale.',
    };
  }

  if (currentBidPrice >= fairPriceMin) {
    const suggestedCounterPrice = Math.round(((currentBidPrice + fairPriceMax) / 2) * 100) / 100;
    return {
      recommendation: 'counter',
      suggestedCounterPrice,
      reasoning: 'Bid is within the fair range but below the top - countering partway toward the max is likely to improve the price without losing the buyer.',
    };
  }

  if (currentBidPrice >= rejectThreshold) {
    return {
      recommendation: 'counter',
      suggestedCounterPrice: Math.round(fairPriceMin * 100) / 100,
      reasoning: 'Bid is below the fair-price floor - countering at the floor holds a fair minimum while staying open to a deal.',
    };
  }

  return {
    recommendation: 'reject',
    suggestedCounterPrice: null,
    reasoning: 'Bid is significantly below fair value - too far off to counter productively; better to wait for a stronger bid.',
  };
}

module.exports = { evaluateBid };
