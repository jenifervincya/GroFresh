const { Kafka, logLevel } = require('kafkajs');

/**
 * Real Kafka integration, replacing src/services/chat.events.js's in-process
 * EventEmitter stand-in. Used for both chat messages and escrow/ledger
 * events, each on their own topic naming scheme.
 *
 * Topics:
 *   grofresh.chat.<batchId>    - chat messages for one batch
 *   grofresh.escrow.<batchId>  - ledger/escrow events for one batch
 *
 * Requires KAFKA_BROKERS in .env (comma-separated, e.g. "localhost:9092"
 * or a managed broker like Upstash Kafka / Confluent Cloud's bootstrap
 * servers). If KAFKA_BROKERS isn't set, this module falls back to a no-op
 * so the server can still boot in local/demo environments without Kafka
 * installed - swap ENABLE_KAFKA=true once a broker is actually reachable.
 */

const brokers = (process.env.KAFKA_BROKERS || '').split(',').map((b) => b.trim()).filter(Boolean);
const kafkaEnabled = brokers.length > 0;

let kafka = null;
let producer = null;
const activeConsumers = new Map(); // topic -> consumer instance

if (kafkaEnabled) {
  kafka = new Kafka({
    clientId: 'grofresh-backend',
    brokers,
    logLevel: logLevel.ERROR,
    ssl: process.env.KAFKA_SSL === 'true',
    sasl:
      process.env.KAFKA_SASL_USERNAME && process.env.KAFKA_SASL_PASSWORD
        ? {
            mechanism: process.env.KAFKA_SASL_MECHANISM || 'plain',
            username: process.env.KAFKA_SASL_USERNAME,
            password: process.env.KAFKA_SASL_PASSWORD,
          }
        : undefined,
  });
  producer = kafka.producer();
}

let producerConnected = false;
async function ensureProducerConnected() {
  if (!kafkaEnabled) return;
  if (!producerConnected) {
    await producer.connect();
    producerConnected = true;
  }
}

/**
 * Publishes a message to a topic. Falls back to a console warning (not a
 * throw) if Kafka isn't configured, so callers don't need to branch on
 * whether Kafka is enabled - this matches the same "safe no-op" pattern
 * used in pricing.service.js and sms.service.js elsewhere in this backend.
 */
async function publish(topic, message) {
  if (!kafkaEnabled) {
    console.warn(`[Kafka not configured] Would publish to ${topic}:`, message);
    return;
  }
  await ensureProducerConnected();
  await producer.send({
    topic,
    messages: [{ value: JSON.stringify(message) }],
  });
}

/**
 * Subscribes to a topic and invokes handler(message) for each new record.
 * Returns an unsubscribe function. Each call spins up its own consumer
 * group so multiple websocket clients on the same batch each get their own
 * feed - fine for demo/small scale, but for real production scale this
 * should move to a shared consumer with in-process fan-out instead of one
 * Kafka consumer group per connected client.
 */
async function subscribe(topic, handler) {
  if (!kafkaEnabled) {
    console.warn(`[Kafka not configured] Would subscribe to ${topic}`);
    return () => {};
  }

  const groupId = `grofresh-${topic}-${Date.now()}-${Math.random().toString(36).slice(2)}`;
  const consumer = kafka.consumer({ groupId });
  await consumer.connect();
  await consumer.subscribe({ topic, fromBeginning: false });

  await consumer.run({
    eachMessage: async ({ message }) => {
      try {
        const parsed = JSON.parse(message.value.toString());
        handler(parsed);
      } catch (err) {
        console.error(`Failed to parse Kafka message on ${topic}:`, err.message);
      }
    },
  });

  activeConsumers.set(topic, consumer);

  return async () => {
    await consumer.disconnect();
    activeConsumers.delete(topic);
  };
}

async function shutdown() {
  if (!kafkaEnabled) return;
  if (producerConnected) await producer.disconnect();
  for (const consumer of activeConsumers.values()) {
    await consumer.disconnect();
  }
}

module.exports = { publish, subscribe, shutdown, kafkaEnabled };
