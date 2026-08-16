const twilio = require('twilio');

/**
 * Real SMS sending via Twilio, replacing the console-log stub.
 *
 * Requires in .env:
 *   TWILIO_ACCOUNT_SID
 *   TWILIO_AUTH_TOKEN
 *   TWILIO_FROM_NUMBER   (a Twilio-purchased/verified number, E.164 format)
 *
 * If those aren't set, falls back to console-logging the message instead of
 * throwing, so local/demo runs still work without a Twilio account. Set
 * SMS_PROVIDER=twilio explicitly once real credentials are in place -
 * this is a deliberate opt-in rather than silently going live.
 *
 * Swap point for later: if the team picks a different gateway (e.g. an
 * India-specific SMS/IVR provider better suited for low-literacy farmers,
 * per the Farmora multilingual voice access requirement), replace the body
 * of sendSms() below - the function signature (phone, message) stays the
 * same for every caller in this backend.
 */

const smsEnabled =
  process.env.SMS_PROVIDER === 'twilio' &&
  process.env.TWILIO_ACCOUNT_SID &&
  process.env.TWILIO_AUTH_TOKEN &&
  process.env.TWILIO_FROM_NUMBER;

let client = null;
if (smsEnabled) {
  client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
}

async function sendSms(phone, message) {
  if (!smsEnabled) {
    console.log(`[SMS stub - not sent, no provider configured] to ${phone}: ${message}`);
    return;
  }

  try {
    await client.messages.create({
      to: phone,
      from: process.env.TWILIO_FROM_NUMBER,
      body: message,
    });
  } catch (err) {
    // Never let a failed SMS take down the request that triggered it
    // (e.g. delivery OTP verification / escrow release should still
    // succeed even if the confirmation text fails to send).
    console.error(`Failed to send SMS to ${phone}:`, err.message);
  }
}

module.exports = { sendSms };
