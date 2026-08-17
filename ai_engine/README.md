# GroFresh AI Engines

Rule-based AI services for GroFresh/Farmora, covering all four AI
capabilities listed in the pitch doc: fair-price estimation, spoilage/
quality scoring, price-formation analysis ("price autopsy"), and a
negotiation agent.

## Why this exists

Neha was originally building these as proper trained models, but became
unavailable. These are rule-based stand-ins using the same API contracts
already agreed on with the backend, so nothing on the backend side needs to
change if/when real models replace these later.

## Endpoints

### `POST /estimate` — fair-price band
```
{ "cropName": "Tomato", "quantityKg": 100 }
-> { "fairPriceMin": 17.6, "fairPriceMax": 23.0 }
```
Base Rs/kg per crop from a static reference table (`src/priceTable.js`),
adjusted down for bulk quantity, then banded 12% below / 15% above. No
`batchId` in the request or response — the backend attaches that itself.

### `POST /quality-score` — spoilage/freshness scoring
```
{ "cropName": "Tomato", "daysSinceHarvest": 5, "storageCondition": "ambient" }
-> { "qualityScore": 29, "spoilageRisk": "high", "estimatedDaysRemaining": 2, "recommendedAction": "..." }
```
`storageCondition` is optional (`"ambient"` default, or `"refrigerated"`,
roughly doubling usable shelf life). Score decays from 100 toward 0 as the
crop approaches its typical shelf life (`src/shelfLifeTable.js`).
`spoilageRisk` is one of `low` / `medium` / `high` / `critical`.

Time-based only — does **not** use sensor input from Yogaprakash/Harsha's
IoT hardware. Per the pitch doc, real sensor data should eventually enrich
this; this is the baseline fallback until that's wired up.

### `POST /negotiate` — bid evaluation / counter-offer suggestion
```
{ "fairPriceMin": 20, "fairPriceMax": 30, "currentBidPrice": 22 }
-> { "recommendation": "counter", "suggestedCounterPrice": 26, "reasoning": "..." }
```
`recommendation` is one of `accept` / `counter` / `reject`.
`suggestedCounterPrice` is only present when `recommendation` is `counter`.
Stateless — no memory of prior negotiation rounds in this version.

### `POST /price-autopsy` — price-formation analysis
```
{
  "fairPriceMin": 20, "fairPriceMax": 30,
  "priceHistory": [
    { "price": 20, "label": "Listed", "time": "2026-08-17T05:00:00Z" },
    { "price": 26, "label": "Bid accepted", "time": "2026-08-17T05:15:00Z" }
  ]
}
-> {
  "summary": "Price rose from Rs.20 to Rs.26 (+6) through bid accepted. Final price of Rs.26 falls in the upper half of fair range (fair band: Rs.20-Rs.30).",
  "steps": [...], "finalPrice": 26, "totalMovement": 6,
  "bandPosition": "upper half of fair range", "percentOfFairBand": 60
}
```
Maps to the pitch doc's "Price Journey Transparency" feature and Neha's
"price autopsy module". Takes the `priceHistory` array already stored/
returned by the backend's batch model (same shape as the `priceHistory`
field on a batch object) and narrates how the price moved and where it
landed relative to fair value. Does not derive prices itself — the backend
remains the source of truth for what actually happened.

All four engines are isolated in their own files (`estimator.js`,
`qualityScorer.js`, `negotiationAgent.js`, `priceAutopsy.js`) so any one can
be replaced with a real trained model independently without touching
`server.js`'s request handling or the other three.

## Setup

```
npm install
npm run dev
```

Runs on port 5000 by default (set `PORT` in `.env` to change).

## Wiring into the backend

Currently only `/estimate` is called by the backend, via
`PRICING_ENGINE_URL` in the backend's `.env`:
```
PRICING_ENGINE_URL=http://localhost:5000
```
`/quality-score`, `/negotiate`, and `/price-autopsy` aren't called by the
backend yet — they exist and are tested standalone, but nothing in
`backend/` invokes them. Wiring those in (e.g. quality score shown on the
batch listing, negotiate suggestions surfaced on a new bid, price-autopsy
powering a "why this price?" view for buyers/farmers) is a backend
integration decision, not something this service does on its own — each
changes what the app shows, so it's worth deciding deliberately rather than
wiring in silently.

## Known limitations

- All four engines use static reference tables and simple rules, not live
  data or trained models. Good enough for a demo; not accurate for real
  trading/spoilage prediction.
- No per-quality/grade adjustment in pricing, no sensor input in quality
  scoring, no negotiation history/memory across rounds, no cross-batch
  market trend analysis in price-autopsy (it only narrates one batch's own
  history).
- Crop name matching is a simple normalized lookup (spaces/case stripped),
  not fuzzy matching — unlisted crops fall back to generic defaults rather
  than erroring.
