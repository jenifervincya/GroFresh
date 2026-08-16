-- GroFresh / Farmora backend schema
-- Run this against your Postgres database before starting the server.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone VARCHAR(15) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  role VARCHAR(20) NOT NULL CHECK (role IN ('farmer', 'buyer')),
  address_lat DOUBLE PRECISION,
  address_lng DOUBLE PRECISION,
  kyc_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (kyc_status IN ('pending', 'submitted', 'verified', 'rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- OTPs are short-lived; store hashed, not plaintext, and expire aggressively.
-- "phone" doubles as a generic lookup key: for purpose='login' it's a real
-- phone number, for purpose='delivery' it's the batch UUID instead - hence
-- the wider column than a phone number alone would need.
CREATE TABLE IF NOT EXISTS otp_codes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone VARCHAR(64) NOT NULL,
  code_hash VARCHAR(255) NOT NULL,
  purpose VARCHAR(20) NOT NULL DEFAULT 'login' CHECK (purpose IN ('login', 'delivery')),
  expires_at TIMESTAMPTZ NOT NULL,
  consumed_at TIMESTAMPTZ,
  attempt_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_otp_codes_phone ON otp_codes(phone);

-- KYC submissions, referencing a pre-signed-upload object key rather than storing files in Postgres.
CREATE TABLE IF NOT EXISTS kyc_submissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id),
  id_type VARCHAR(50) NOT NULL,
  id_number VARCHAR(100) NOT NULL,
  document_object_key VARCHAR(500) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Batches (produce listings)
CREATE TABLE IF NOT EXISTS batches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  crop_name VARCHAR(255) NOT NULL,
  seller_id UUID NOT NULL REFERENCES users(id),
  buyer_id UUID REFERENCES users(id),
  quantity_kg DOUBLE PRECISION NOT NULL,
  fair_price_min DOUBLE PRECISION,
  fair_price_max DOUBLE PRECISION,
  current_bid_price DOUBLE PRECISION,
  status VARCHAR(20) NOT NULL DEFAULT 'listed'
    CHECK (status IN ('listed', 'bidding', 'accepted', 'in_transit', 'delivered', 'paid')),
  image_url VARCHAR(500),
  listed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_batches_seller ON batches(seller_id);
CREATE INDEX IF NOT EXISTS idx_batches_status ON batches(status);

-- Bids placed on a batch
CREATE TABLE IF NOT EXISTS bids (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  batch_id UUID NOT NULL REFERENCES batches(id),
  buyer_id UUID NOT NULL REFERENCES users(id),
  amount DOUBLE PRECISION NOT NULL,
  accepted BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bids_batch ON bids(batch_id);

-- Price journey / history shown to buyer+farmer
CREATE TABLE IF NOT EXISTS price_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  batch_id UUID NOT NULL REFERENCES batches(id),
  price DOUBLE PRECISION NOT NULL,
  label VARCHAR(100) NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_price_history_batch ON price_history(batch_id);

-- Tracking steps per batch (pickup -> transit -> delivered -> paid)
CREATE TABLE IF NOT EXISTS tracking_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  batch_id UUID NOT NULL REFERENCES batches(id),
  label VARCHAR(100) NOT NULL,
  step_order INT NOT NULL,
  completed BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_tracking_events_batch ON tracking_events(batch_id);

-- Chat messages, scoped per batch (buyer <-> seller)
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  batch_id UUID NOT NULL REFERENCES batches(id),
  sender_id UUID NOT NULL REFERENCES users(id),
  text TEXT NOT NULL,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_messages_batch ON messages(batch_id);

-- Tamper-evident, hash-chained ledger for escrow/trust events.
-- Each row's hash is derived from its own content plus the previous row's
-- hash, so any retroactive edit breaks the chain and is detectable.
CREATE TABLE IF NOT EXISTS ledger_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  batch_id UUID NOT NULL REFERENCES batches(id),
  event_type VARCHAR(50) NOT NULL, -- e.g. BID_ACCEPTED, DELIVERY_VERIFIED, PAYMENT_RELEASED
  payload JSONB NOT NULL,
  prev_hash VARCHAR(64) NOT NULL,
  entry_hash VARCHAR(64) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ledger_entries_batch ON ledger_entries(batch_id);
