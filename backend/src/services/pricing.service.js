/**
 * Wraps Neha's AI fair-price engine. CONFIRMED sync (per Neha, Aug 2026):
 * addBatch calls this inline, gets fairPriceMin/fairPriceMax back in the
 * same request/response cycle, no queue or webhook needed for now.
 *
 * Still kept behind this single function so it can move async later if
 * inference latency becomes a problem post-demo - only this file and the
 * PRICING_ENGINE_URL env var would need to change, not any caller.
 *
 * Needs from Neha before this actually works end-to-end:
 *  - the real base URL for her service (PRICING_ENGINE_URL in .env)
 *  - the exact request path/payload her endpoint expects (currently
 *    assumed as POST {base}/estimate with { cropName, quantityKg })
 *  - confirm whether her response includes batchId or just the price band
 *    (her example response shows batchId, but addBatch generates the
 *    batchId itself - clarify whether she needs it passed in first, or if
 *    that field is just for her own logging)
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
