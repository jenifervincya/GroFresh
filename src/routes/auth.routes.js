const express = require('express');
const authController = require('../controllers/auth.controller');

const router = express.Router();

router.post('/register', authController.register);
router.post('/otp/request', authController.requestOtp);
router.post('/otp/verify', authController.verifyOtp);

module.exports = router;
