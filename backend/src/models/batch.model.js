const pool = require('../config/db');

// Haversine distance in km between two lat/lng points.
const DISTANCE_SQL = `
  (
    6371 * acos(
      cos(radians($1)) * cos(radians(seller_addr.address_lat)) *
      cos(radians(seller_addr.address_lng) - radians($2)) +
      sin(radians($1)) * sin(radians(seller_addr.address_lat))
    )
  )
`;

const BATCH_SELECT = `
  SELECT
    b.id, b.crop_name, b.seller_id, seller.name AS seller_name, seller.phone AS seller_phone,
    b.buyer_id, buyer.name AS buyer_name, buyer.phone AS buyer_phone,
    b.quantity_kg, b.fair_price_min, b.fair_price_max, b.current_bid_price,
    b.status, b.listed_at, b.image_url
  FROM batches b
  JOIN users seller ON seller.id = b.seller_id
  LEFT JOIN users buyer ON buyer.id = b.buyer_id
`;

function toBatchShape(row, distanceKm, priceHistory, exposePhones) {
  return {
    id: row.id,
    cropName: row.crop_name,
    sellerId: row.seller_id,
    sellerName: row.seller_name,
    sellerPhone: exposePhones ? row.seller_phone : null,
    buyerId: row.buyer_id,
    buyerName: row.buyer_name,
    buyerPhone: exposePhones ? row.buyer_phone : null,
    quantityKg: row.quantity_kg,
    fairPriceMin: row.fair_price_min,
    fairPriceMax: row.fair_price_max,
    currentBidPrice: row.current_bid_price,
    distanceKm: distanceKm ?? null,
    status: row.status,
    listedAt: row.listed_at,
    imageUrl: row.image_url,
    priceHistory: (priceHistory || []).map((p) => ({
      time: p.occurred_at,
      price: p.price,
      label: p.label,
    })),
  };
}

// Q9 decision: phone numbers are masked/relayed by default, not exposed raw.
// Flip this once the relay-calling feature exists, or per-batch once accepted.
const EXPOSE_PHONES = false;

async function getPriceHistory(batchId) {
  const { rows } = await pool.query(
    `SELECT price, label, occurred_at FROM price_history WHERE batch_id = $1 ORDER BY occurred_at ASC`,
    [batchId]
  );
  return rows;
}

// GET /batches?lat=&lng=&sort=nearest
// Q3 decision: backend looks up by stored seller address, using the buyer's
// passed lat/lng only as the reference point for distance sorting.
async function listNearby(buyerLat, buyerLng) {
  const { rows } = await pool.query(
    `SELECT b.*, seller.name AS seller_name, seller.phone AS seller_phone,
            seller.address_lat, seller.address_lng,
            buyer.name AS buyer_name, buyer.phone AS buyer_phone
     FROM batches b
     JOIN users seller ON seller.id = b.seller_id
     LEFT JOIN users buyer ON buyer.id = b.buyer_id
     ORDER BY b.listed_at DESC`
  );

  const withDistance = rows.map((row) => {
    let distanceKm = null;
    if (buyerLat != null && buyerLng != null && row.address_lat != null && row.address_lng != null) {
      const R = 6371;
      const dLat = ((row.address_lat - buyerLat) * Math.PI) / 180;
      const dLng = ((row.address_lng - buyerLng) * Math.PI) / 180;
      const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos((buyerLat * Math.PI) / 180) *
          Math.cos((row.address_lat * Math.PI) / 180) *
          Math.sin(dLng / 2) ** 2;
      distanceKm = R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
    return { row, distanceKm };
  });

  withDistance.sort((a, b) => (a.distanceKm ?? Infinity) - (b.distanceKm ?? Infinity));

  const results = [];
  for (const { row, distanceKm } of withDistance) {
    const history = await getPriceHistory(row.id);
    results.push(toBatchShape(row, distanceKm, history, EXPOSE_PHONES));
  }
  return results;
}

async function getById(batchId) {
  const { rows } = await pool.query(`${BATCH_SELECT} WHERE b.id = $1`, [batchId]);
  if (rows.length === 0) return null;
  const history = await getPriceHistory(batchId);
  return toBatchShape(rows[0], null, history, EXPOSE_PHONES);
}

async function listBySeller(sellerId) {
  const { rows } = await pool.query(`${BATCH_SELECT} WHERE b.seller_id = $1 ORDER BY b.listed_at DESC`, [
    sellerId,
  ]);
  const results = [];
  for (const row of rows) {
    const history = await getPriceHistory(row.id);
    results.push(toBatchShape(row, null, history, EXPOSE_PHONES));
  }
  return results;
}

async function create({ cropName, quantityKg, sellerId, imageUrl, fairPriceMin, fairPriceMax }) {
  const { rows } = await pool.query(
    `INSERT INTO batches (crop_name, quantity_kg, seller_id, image_url, fair_price_min, fair_price_max, status)
     VALUES ($1, $2, $3, $4, $5, $6, 'listed')
     RETURNING *`,
    [cropName, quantityKg, sellerId, imageUrl || null, fairPriceMin ?? null, fairPriceMax ?? null]
  );
  const batch = rows[0];

  await pool.query(
    `INSERT INTO price_history (batch_id, price, label) VALUES ($1, $2, 'Listed')`,
    [batch.id, fairPriceMin ?? 0]
  );

  // Seed the four tracking steps for this batch up front.
  const steps = ['Picked up', 'In transit', 'Delivered', 'Paid'];
  for (let i = 0; i < steps.length; i++) {
    await pool.query(
      `INSERT INTO tracking_events (batch_id, label, step_order, completed) VALUES ($1, $2, $3, false)`,
      [batch.id, steps[i], i]
    );
  }

  return getById(batch.id);
}

async function placeBid(batchId, buyerId, amount) {
  const { rows } = await pool.query(
    `INSERT INTO bids (batch_id, buyer_id, amount) VALUES ($1, $2, $3) RETURNING *`,
    [batchId, buyerId, amount]
  );
  await pool.query(`UPDATE batches SET current_bid_price = $1, status = 'bidding' WHERE id = $2`, [
    amount,
    batchId,
  ]);
  await pool.query(
    `INSERT INTO price_history (batch_id, price, label) VALUES ($1, $2, 'Bid placed')`,
    [batchId, amount]
  );
  return rows[0];
}

async function acceptBid(batchId, bidId) {
  const { rows } = await pool.query(`SELECT * FROM bids WHERE id = $1 AND batch_id = $2`, [
    bidId,
    batchId,
  ]);
  if (rows.length === 0) return null;
  const bid = rows[0];

  await pool.query(`UPDATE bids SET accepted = true WHERE id = $1`, [bidId]);
  await pool.query(`UPDATE batches SET status = 'accepted', buyer_id = $1, current_bid_price = $2 WHERE id = $3`, [
    bid.buyer_id,
    bid.amount,
    batchId,
  ]);
  await pool.query(
    `INSERT INTO price_history (batch_id, price, label) VALUES ($1, $2, 'Bid accepted')`,
    [batchId, bid.amount]
  );
  return getById(batchId);
}

// Internal-only lookup, bypasses the Q9 API-facing mask - used by backend
// services (SMS/OTP delivery) that need the real number, not by any route
// response sent to the app.
async function getContactPhones(batchId) {
  const { rows } = await pool.query(
    `SELECT seller.phone AS seller_phone, buyer.phone AS buyer_phone
     FROM batches b
     JOIN users seller ON seller.id = b.seller_id
     LEFT JOIN users buyer ON buyer.id = b.buyer_id
     WHERE b.id = $1`,
    [batchId]
  );
  if (rows.length === 0) return null;
  return { sellerPhone: rows[0].seller_phone, buyerPhone: rows[0].buyer_phone };
}

module.exports = {
  listNearby,
  getById,
  listBySeller,
  create,
  placeBid,
  acceptBid,
  getPriceHistory,
  getContactPhones,
};
