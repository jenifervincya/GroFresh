const pool = require('../config/db');

async function submit({ userId, idType, idNumber, documentObjectKey }) {
  const { rows } = await pool.query(
    `INSERT INTO kyc_submissions (user_id, id_type, id_number, document_object_key)
     VALUES ($1, $2, $3, $4) RETURNING *`,
    [userId, idType, idNumber, documentObjectKey]
  );
  await pool.query(`UPDATE users SET kyc_status = 'submitted' WHERE id = $1`, [userId]);
  return rows[0];
}

module.exports = { submit };
