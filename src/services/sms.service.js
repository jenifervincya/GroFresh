/**
 * Placeholder SMS sender. Swap the body of sendSms() for a real gateway call
 * once it's confirmed whether OTP delivery uses the same SMS gateway as
 * delivery-confirmation OTPs (see Tamil's open question in the requirements doc).
 *
 * In development this just logs to the console so you can test the OTP flow
 * end-to-end without a live gateway.
 */
async function sendSms(phone, message) {
  if (process.env.NODE_ENV === 'production' && process.env.SMS_GATEWAY_BASE_URL) {
    // TODO: wire up real gateway call here, e.g.:
    // await fetch(`${process.env.SMS_GATEWAY_BASE_URL}/send`, {
    //   method: 'POST',
    //   headers: { Authorization: `Bearer ${process.env.SMS_GATEWAY_API_KEY}` },
    //   body: JSON.stringify({ to: phone, message }),
    // });
    console.warn('SMS gateway not yet wired up - message not actually sent.');
  }

  console.log(`[SMS to ${phone}]: ${message}`);
}

module.exports = { sendSms };
