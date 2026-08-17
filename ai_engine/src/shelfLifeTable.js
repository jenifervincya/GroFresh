/**
 * Rule-based shelf-life reference, in days, for common Indian crops at
 * ambient storage. Refrigerated storage roughly doubles shelf life for
 * most produce (applied as a multiplier in qualityScorer.js), though this
 * varies a lot by crop in reality - treat this as a demo-level default,
 * same caveat as priceTable.js.
 */
const SHELF_LIFE_DAYS = {
  tomato: 7,
  onion: 30,
  potato: 60,
  brinjal: 5,
  cabbage: 14,
  cauliflower: 7,
  carrot: 21,
  beans: 5,
  okra: 3,
  ladiesfinger: 3,
  bhindi: 3,
  greenchilli: 10,
  chilli: 10,
  capsicum: 10,
  cucumber: 7,
  pumpkin: 30,
  bittergourd: 5,
  bottlegourd: 5,
  drumstick: 5,
  radish: 10,
  beetroot: 21,
  spinach: 3,
  coriander: 3,
  mint: 4,
  ginger: 60,
  garlic: 90,
  mango: 7,
  banana: 5,
  papaya: 5,
  watermelon: 10,
  guava: 5,
  pomegranate: 30,
  orange: 21,
  grapes: 7,
  apple: 45,
  rice: 365,
  wheat: 365,
  maize: 180,
  groundnut: 180,
  sugarcane: 3,
  cotton: 365,
  turmeric: 180,
  soybean: 180,
};

const DEFAULT_SHELF_LIFE_DAYS = 7; // conservative fallback for unlisted crops

function normalizeCropName(cropName) {
  return String(cropName || '')
    .toLowerCase()
    .replace(/[^a-z]/g, '');
}

function getShelfLifeDays(cropName) {
  const key = normalizeCropName(cropName);
  return SHELF_LIFE_DAYS[key] ?? DEFAULT_SHELF_LIFE_DAYS;
}

module.exports = { getShelfLifeDays, SHELF_LIFE_DAYS, DEFAULT_SHELF_LIFE_DAYS };
