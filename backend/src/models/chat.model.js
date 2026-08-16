const pool = require('../config/db');

async function listMessages(batchId) {
  const { rows } = await pool.query(
    `SELECT id, sender_id, text, sent_at FROM messages WHERE batch_id = $1 ORDER BY sent_at ASC`,
    [batchId]
  );
  return rows.map((r) => ({ id: r.id, senderId: r.sender_id, text: r.text, sentAt: r.sent_at }));
}

async function postMessage(batchId, senderId, text) {
  const { rows } = await pool.query(
    `INSERT INTO messages (batch_id, sender_id, text) VALUES ($1, $2, $3)
     RETURNING id, sender_id, text, sent_at`,
    [batchId, senderId, text]
  );
  const r = rows[0];
  return { id: r.id, senderId: r.sender_id, text: r.text, sentAt: r.sent_at };
}

module.exports = { listMessages, postMessage };
