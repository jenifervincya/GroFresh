const express = require('express');
const authController = require('../controllers/auth.controller');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.post('/register', authController.register);
router.post('/otp/request', authController.requestOtp);
router.post('/otp/verify', authController.verifyOtp);

// Refresh requires an already-valid JWT - this is the "returning user"
// path that avoids OTP as long as the app's persisted token hasn't expired.
router.post('/token/refresh', requireAuth, authController.refreshToken);

module.exports = router;
