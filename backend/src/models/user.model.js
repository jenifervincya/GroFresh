const pool = require('../config/db');

async function findByPhone(phone) {
  const { rows } = await pool.query('SELECT * FROM users WHERE phone = $1', [phone]);
  return rows[0] || null;
}

async function findById(id) {
  const { rows } = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
  return rows[0] || null;
}

async function create({ phone, name, role }) {
  const { rows } = await pool.query(
    `INSERT INTO users (phone, name, role) VALUES ($1, $2, $3) RETURNING *`,
    [phone, name, role]
  );
  return rows[0];
}

// Flips phone_verified to true. Called once, after the FIRST successful OTP
// verify for a given user - never reset to false afterward.
async function markPhoneVerified(userId) {
  await pool.query(`UPDATE users SET phone_verified = true WHERE id = $1`, [userId]);
}

module.exports = { findByPhone, findById, create, markPhoneVerified };
