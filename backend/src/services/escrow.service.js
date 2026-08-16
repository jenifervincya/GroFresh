const crypto = require('crypto');
const { EventEmitter } = require('events');
const pool = require('../config/db');

// In-process event bus. Swap this for a real Kafka producer/consumer once
// the event-streaming layer is wired up - other services (e.g. notifications)
// can subscribe to 'PAYMENT_RELEASED' the same way regardless of transport.
const escrowEvents = new EventEmitter();

const GENESIS_HASH = '0'.repeat(64);

function computeHash({ batchId, eventType, payload, prevHash }) {
  const content = JSON.stringify({ batchId, eventType, payload, prevHash });
  return crypto.createHash('sha256').update(content).digest('hex');
}

async function getLastHash(batchId) {
  const { rows } = await pool.query(
    `SELECT entry_hash FROM ledger_entries WHERE batch_id = $1 ORDER BY created_at DESC LIMIT 1`,
    [batchId]
  );
  return rows.length > 0 ? rows[0].entry_hash : GENESIS_HASH;
}

async function appendLedgerEntry(batchId, eventType, payload) {
  const prevHash = await getLastHash(batchId);
  const entryHash = computeHash({ batchId, eventType, payload, prevHash });

  await pool.query(
    `INSERT INTO ledger_entries (batch_id, event_type, payload, prev_hash, entry_hash)
     VALUES ($1, $2, $3, $4, $5)`,
    [batchId, eventType, payload, prevHash, entryHash]
  );

  return entryHash;
}

// Verifies the full chain for a batch hasn't been tampered with.
async function verifyChain(batchId) {
  const { rows } = await pool.query(
    `SELECT event_type, payload, prev_hash, entry_hash, created_at
     FROM ledger_entries WHERE batch_id = $1 ORDER BY created_at ASC`,
    [batchId]
  );

  let expectedPrev = GENESIS_HASH;
  for (const row of rows) {
    if (row.prev_hash !== expectedPrev) return false;
    const recomputed = computeHash({
      batchId,
      eventType: row.event_type,
      payload: row.payload,
      prevHash: row.prev_hash,
    });
    if (recomputed !== row.entry_hash) return false;
    expectedPrev = row.entry_hash;
  }
  return true;
}

/**
 * Called when the buyer/receiving agent verifies the delivery OTP.
 * This is THE trigger for PAYMENT_RELEASED, per the Farmora spec:
 * payment is mathematically tied to confirmed delivery, not trust.
 */
async function releasePaymentOnDelivery(batchId) {
  await appendLedgerEntry(batchId, 'DELIVERY_VERIFIED', { batchId });
  const hash = await appendLedgerEntry(batchId, 'PAYMENT_RELEASED', { batchId });

  await pool.query(`UPDATE batches SET status = 'paid' WHERE id = $1`, [batchId]);

  escrowEvents.emit('PAYMENT_RELEASED', { batchId, entryHash: hash });
  return hash;
}

module.exports = { appendLedgerEntry, verifyChain, releasePaymentOnDelivery, escrowEvents };
