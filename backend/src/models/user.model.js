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

module.exports = { findByPhone, findById, create };
