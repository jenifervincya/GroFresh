/**
 * Rule-based base price reference, in Rs/kg, for common Indian crops.
 *
 * These are reasonable defaults based on typical mandi (wholesale market)
 * price ranges, NOT live/scraped data — there's no real-time feed behind
 * this. Treat these as a starting point for the demo, not production
 * pricing truth. Swap in real mandi API data (e.g. Agmarknet) post-demo if
 * the team wants live-accurate pricing.
 *
 * Values represent a typical mid-season wholesale price. The pricing
 * service applies a band (+/- percentage) around this base in server.js
 * rather than storing min/max here directly, so the spread logic lives in
 * one place.
 */
const BASE_PRICES_PER_KG = {
  tomato: 20,
  onion: 25,
  potato: 18,
  brinjal: 22,
  cabbage: 15,
  cauliflower: 20,
  carrot: 28,
  beans: 35,
  okra: 30, // ladies finger / bhindi
  ladiesfinger: 30,
  bhindi: 30,
  greenchilli: 40,
  chilli: 40,
  capsicum: 35,
  cucumber: 18,
  pumpkin: 15,
  bittergourd: 30,
  bottlegourd: 15,
  drumstick: 45,
  radish: 18,
  beetroot: 25,
  spinach: 20,
  coriander: 30,
  mint: 25,
  ginger: 80,
  garlic: 90,
  mango: 45,
  banana: 20,
  papaya: 18,
  watermelon: 12,
  guava: 30,
  pomegranate: 90,
  orange: 40,
  grapes: 55,
  apple: 100,
  rice: 35,
  wheat: 25,
  maize: 20,
  groundnut: 65,
  sugarcane: 3.5,
  cotton: 60,
  turmeric: 70,
  soybean: 40,
};

// Fallback used when the crop isn't in the table above. Deliberately a wide
// mid-range Rs/kg guess so an unknown crop doesn't get an absurd price.
const DEFAULT_BASE_PRICE = 25;

function normalizeCropName(cropName) {
  return String(cropName || '')
    .toLowerCase()
    .replace(/[^a-z]/g, ''); // strip spaces/punctuation so "Green Chilli" matches "greenchilli"
}

function getBasePrice(cropName) {
  const key = normalizeCropName(cropName);
  return BASE_PRICES_PER_KG[key] ?? DEFAULT_BASE_PRICE;
}

module.exports = { getBasePrice, BASE_PRICES_PER_KG, DEFAULT_BASE_PRICE };
