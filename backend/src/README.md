# GroFresh Backend

Backend for the Farmora / GroFresh app, built against Tamil's requirements doc.
Tested end-to-end locally: register → OTP login → list batch → browse →
bid → accept → delivery OTP → escrow release → chat.

## Status: all endpoints from the requirements doc are built

**Auth**
- `POST /auth/register`
- `POST /auth/otp/request`
- `POST /auth/otp/verify`

**KYC** (Q4 decision: pre-signed upload URL flow, not raw multipart)
- `POST /kyc/upload-url` — not in Tamil's original doc; needed to issue the
  upload URL before `/kyc/submit`, since Q4 was decided as pre-signed URLs.
- `POST /kyc/submit`

**Batches**
- `GET /batches?lat=&lng=&sort=nearest` — Q3 decision: distance is computed
  from the seller's stored address, buyer's lat/lng is only the reference point.
- `GET /batches/:batchId`
- `POST /batches/:batchId/bids`
- `GET /sellers/:sellerId/batches`
- `POST /batches` — includes AI fair-price band via `src/services/pricing.service.js`.
  **Still blocked on Q5** (sync vs async) — currently returns `null` for the
  price band until Neha's engine is wired in; see that file for the exact
  swap-in point once she confirms.
- `POST /batches/:batchId/bids/:bidId/accept`

**Delivery / Escrow** (Jeni's core ownership area)
- `GET /batches/:batchId/tracking`
- `POST /batches/:batchId/delivery/generate-otp` — not in Tamil's original
  doc; something has to issue the delivery OTP before it can be verified.
  Currently callable by the seller; flag to Archana as a candidate for the
  IoT tracker to trigger automatically once hardware integration lands.
- `POST /batches/:batchId/delivery/verify-otp` — verified end-to-end:
  triggers `DELIVERY_VERIFIED` + `PAYMENT_RELEASED` ledger entries (hash-chained,
  tamper-evident per the Farmora trust-layer spec), updates tracking to
  `Delivered`/`Paid`. Q6 decision: response includes updated tracking directly.

**Notifications** (Q7 decision: built as app-triggered per the reply sent to Tamil)
- `POST /notifications/trigger`

**Chat** (Q8 decision: Kafka-per-batch-topic, currently an in-process event
bus stand-in — see `src/services/chat.events.js` for the swap-in point)
- `GET /batches/:batchId/messages`
- `POST /batches/:batchId/messages` — also publishes to `ws://.../ws/batches/:batchId/messages?token=<jwt>`
  for real-time delivery instead of polling.

## Setup

1. Install dependencies:
   ```
   npm install
   ```
2. Copy `.env.example` to `.env` and fill in `DATABASE_URL` and `JWT_SECRET`.
3. Create the database, then run the schema:
   ```
   psql $DATABASE_URL -f src/db/schema.sql
   ```
4. Start the server:
   ```
   npm run dev
   ```
5. Health check: `GET http://localhost:4000/health`

## Decisions baked into this build (per the reply sent to Tamil)

- Auth: `Authorization: Bearer <jwt>` on every request after login.
- OTP: 6-digit, 5-minute expiry, hashed at rest, max 5 verify attempts.
- Register/OTP-verify responses use `userId` and `token` as field names.
- Phone numbers (`sellerPhone`/`buyerPhone` on batch objects): masked by
  default (`null` in API responses) per the Q9 decision — see
  `EXPOSE_PHONES` in `src/models/batch.model.js` to flip this once a relay-
  calling feature exists. Backend services still use real numbers internally
  for SMS via `batchModel.getContactPhones()`.
- SMS sending is a console-log stub in `src/services/sms.service.js` — swap
  in the real gateway once the provider is confirmed.
- Escrow ledger is hash-chained (`src/services/escrow.service.js`,
  `verifyChain()` can audit any batch's history for tampering).

## Two items still genuinely blocking full correctness

- **Q5 (Neha):** sync vs async AI fair-price band. `addBatch` works today but
  always returns `null` for `fairPriceMin`/`fairPriceMax` until this is wired up.
- **Kafka:** chat and escrow events currently run on an in-process
  EventEmitter stand-in, not real Kafka. Fine for a single server instance;
  will need real Kafka before this scales past one process (see
  `src/services/chat.events.js` and `src/services/escrow.service.js` for the
  exact swap-in points, deliberately isolated so no controller code changes).

