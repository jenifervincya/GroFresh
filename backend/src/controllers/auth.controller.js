const jwt = require('jsonwebtoken');
const userModel = require('../models/user.model');
const otpService = require('../services/otp.service');
const smsService = require('../services/sms.service');

function signToken(userId) {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
}

// POST /auth/register
// { phone, name, role } -> { userId }
async function register(req, res) {
  const { phone, name, role } = req.body;

  if (!phone || !name || !role) {
    return res.status(400).json({ error: 'phone, name, and role are required' });
  }
  if (!['farmer', 'buyer'].includes(role)) {
    return res.status(400).json({ error: 'role must be farmer or buyer' });
  }

  const existing = await userModel.findByPhone(phone);
  if (existing) {
    return res.status(409).json({ error: 'phone already registered' });
  }

  const user = await userModel.create({ phone, name, role });
  return res.status(201).json({ userId: user.id });
}

// POST /auth/otp/request
// { phone } -> 200 OK, no body
async function requestOtp(req, res) {
  const { phone } = req.body;
  if (!phone) {
    return res.status(400).json({ error: 'phone is required' });
  }

  const code = await otpService.requestOtp(phone, 'login');
  await smsService.sendSms(phone, `Your GroFresh login code is ${code}`);

  return res.status(200).end();
}

// POST /auth/otp/verify
// { phone, otp } -> { token, userId, phoneVerified }
async function verifyOtp(req, res) {
  const { phone, otp } = req.body;
  if (!phone || !otp) {
    return res.status(400).json({ error: 'phone and otp are required' });
  }

  const isValid = await otpService.verifyOtp(phone, otp, 'login');
  if (!isValid) {
    return res.status(401).json({ error: 'invalid or expired OTP' });
  }

  const user = await userModel.findByPhone(phone);
  if (!user) {
    return res.status(404).json({ error: 'no account found for this phone, register first' });
  }

  // First successful OTP verify for this account -> mark phone as verified.
  // From now on the app should persist the JWT (see AuthSession/shared_preferences
  // on the app side) so the user isn't sent through OTP again on every open -
  // only re-request OTP if the token is lost/expired (new device, reinstall).
  if (!user.phone_verified) {
    await userModel.markPhoneVerified(user.id);
  }

  const token = signToken(user.id);
  return res.status(200).json({ token, userId: user.id, phoneVerified: true });
}

// POST /auth/token/refresh
// Requires a currently-valid JWT (requireAuth middleware already ran).
// Issues a fresh token with a renewed expiry, so a returning user with a
// still-valid session never has to go through OTP again - this is the
// "just login is enough next time" path. If the token has already expired,
// requireAuth rejects the request before this handler runs, and the app
// falls back to the OTP flow (request -> verify) as normal.
async function refreshToken(req, res) {
  const token = signToken(req.userId);
  return res.status(200).json({ token, userId: req.userId });
}

module.exports = { register, requestOtp, verifyOtp, refreshToken };
