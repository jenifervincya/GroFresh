const crypto = require('crypto');
const pool = require('../config/db');

const OTP_TTL_SECONDS = parseInt(process.env.OTP_TTL_SECONDS || '300', 10);
const OTP_LENGTH = parseInt(process.env.OTP_LENGTH || '6', 10);
const MAX_ATTEMPTS = 5;

function generateCode() {
  const max = 10 ** OTP_LENGTH;
  const code = crypto.randomInt(0, max).toString().padStart(OTP_LENGTH, '0');
  return code;
}

function hashCode(code, phone) {
  return crypto.createHash('sha256').update(`${phone}:${code}`).digest('hex');
}

/**
 * Creates and stores a new OTP for a phone number, returns the plaintext code
 * so the caller can hand it to the SMS gateway. Never log the plaintext code.
 */
async function requestOtp(phone, purpose = 'login') {
  const code = generateCode();
  const codeHash = hashCode(code, phone);
  const expiresAt = new Date(Date.now() + OTP_TTL_SECONDS * 1000);

  await pool.query(
    `INSERT INTO otp_codes (phone, code_hash, purpose, expires_at)
     VALUES ($1, $2, $3, $4)`,
    [phone, codeHash, purpose, expiresAt]
  );

  return code;
}

/**
 * Verifies a submitted OTP. Returns true/false. Marks the row consumed on success,
 * and increments attempt_count on failure to allow rate limiting.
 */
async function verifyOtp(phone, submittedCode, purpose = 'login') {
  const { rows } = await pool.query(
    `SELECT id, code_hash, expires_at, consumed_at, attempt_count
     FROM otp_codes
     WHERE phone = $1 AND purpose = $2
     ORDER BY created_at DESC
     LIMIT 1`,
    [phone, purpose]
  );

  if (rows.length === 0) return false;
  const row = rows[0];

  if (row.consumed_at) return false;
  if (new Date(row.expires_at) < new Date()) return false;
  if (row.attempt_count >= MAX_ATTEMPTS) return false;

  const submittedHash = hashCode(submittedCode, phone);
  const isValid = submittedHash === row.code_hash;

  if (isValid) {
    await pool.query(`UPDATE otp_codes SET consumed_at = now() WHERE id = $1`, [row.id]);
  } else {
    await pool.query(`UPDATE otp_codes SET attempt_count = attempt_count + 1 WHERE id = $1`, [row.id]);
  }

  return isValid;
}

module.exports = { requestOtp, verifyOtp };
