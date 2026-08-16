# GroFresh (Farmora)

A fair-chain agricultural marketplace connecting farmers directly to buyers —
removing the middleman markup, verifying delivery before releasing payment,
and staying accessible to farmers with low smartphone/digital literacy through
voice and SMS.

## The Problem

Farmers routinely lose income to information asymmetry: no visibility into
fair market prices, no reliable way to verify trust with a buyer or
middleman, no guarantee that payment follows delivery, and no path into a
digital marketplace for those without smartphone access or literacy.

## What This Repo Contains

The software side of the platform:

- **Reverse auction marketplace** — farmers list produce, buyers bid
  competitively instead of a single middleman setting the price.
- **AI-driven fair-price guidance** — an estimated fair price band per
  batch, based on market conditions.
- **Escrow-based payments** — buyer funds are held and only released once
  delivery is confirmed via OTP, removing non-payment risk.
- **Trust & reputation ledger** — a tamper-evident, hash-chained record of
  every transaction, visible to both sides.
- **Price journey transparency** — a full, visible history of how a batch's
  price was formed, from listing to final sale.
- **Voice, SMS & multilingual access** — so the app isn't the only way in.

## Team & Ownership

| Member | Area |
|---|---|
| Jeni | Backend core, Kafka, trust/ledger layer — auction logic, escrow hold-and-release, OTP-gated payment release, hash-chained ledger, reputation service |
| Tamil | Mobile app — build & launch, registration/KYC flow, SMS/IVR templates |
| Archana | DevOps, integration testing, hardware↔software integration lead |
| Neha | AI/pricing — fair-price model, spoilage/quality scoring, negotiation agent |
| Yogaprakash | Hardware — IoT batch tracker, weight sensor |
| Harsha | Hardware — quality/freshness sensor, RFID/NFC checkpoint tags |"
