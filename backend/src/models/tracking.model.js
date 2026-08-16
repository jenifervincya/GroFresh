const pool = require('../config/db');

async function getTracking(batchId) {
  const { rows } = await pool.query(
    `SELECT label, completed, completed_at
     FROM tracking_events
     WHERE batch_id = $1
     ORDER BY step_order ASC`,
    [batchId]
  );
  return rows.map((r) => ({
    label: r.label,
    completed: r.completed,
    timestamp: r.completed_at,
  }));
}

async function markStepComplete(batchId, label) {
  await pool.query(
    `UPDATE tracking_events SET completed = true, completed_at = now()
     WHERE batch_id = $1 AND label = $2`,
    [batchId, label]
  );
}

module.exports = { getTracking, markStepComplete };
