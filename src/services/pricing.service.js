/**
 * Wraps Neha's AI fair-price engine. Q5 (sync vs async) is still unconfirmed
 * with her as of this build — see README. This function is written so either
 * answer slots in without changing any callers:
 *
 *  - If her model is synchronous: replace the body below with a real HTTP
 *    call to her service and return the real min/max immediately.
 *  - If her model is async: leave this returning `null` fields, keep
 *    addBatch responding immediately (already does), and add a webhook
 *    endpoint or Kafka consumer that PATCHes the batch's fair_price_min/max
 *    once her model finishes, then re-emits a price_history "AI estimate" row.
 *
 * Until she confirms, addBatch will list with null fair price band rather
 * than blocking or guessing a number.
 */
async function estimateFairPrice({ cropName, quantityKg }) {
  const pricingUrl = process.env.PRICING_ENGINE_URL;

  if (!pricingUrl) {
    // Not wired up yet - safe no-op fallback.
    return { fairPriceMin: null, fairPriceMax: null };
  }

  try {
    const response = await fetch(`${pricingUrl}/estimate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ cropName, quantityKg }),
    });
    if (!response.ok) throw new Error(`pricing engine returned ${response.status}`);
    const data = await response.json();
    return { fairPriceMin: data.fairPriceMin ?? null, fairPriceMax: data.fairPriceMax ?? null };
  } catch (err) {
    console.error('Pricing engine call failed, falling back to null band:', err.message);
    return { fairPriceMin: null, fairPriceMax: null };
  }
}

module.exports = { estimateFairPrice };
