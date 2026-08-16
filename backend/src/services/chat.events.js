const kafkaClient = require('./kafka.client');

/**
 * Chat event bus. Now backed by real Kafka (one topic per batch:
 * grofresh.chat.<batchId>) when KAFKA_BROKERS is configured, falling back
 * to a console-warning no-op otherwise so local/demo runs without a broker
 * still boot cleanly.
 *
 * This keeps the same publish/subscribe interface the rest of the backend
 * already used against the old in-process EventEmitter stand-in, so
 * chat.controller.js and server.js's websocket layer didn't need to change.
 */

function topicFor(batchId) {
  return `grofresh.chat.${batchId}`;
}

function publish(batchId, message) {
  // Fire-and-forget from the caller's perspective (chat.controller.js
  // doesn't await this today) - errors are logged inside kafka.client.js.
  kafkaClient.publish(topicFor(batchId), message).catch((err) => {
    console.error(`Failed to publish chat message for batch ${batchId}:`, err.message);
  });
}

/**
 * Subscribes to a batch's chat topic. Returns an unsubscribe function.
 * Note: subscribing is async under the hood (Kafka consumer connect), but
 * callers (server.js websocket upgrade handler) treat this as fire-and-forget
 * too - the unsubscribe function is attached once the consumer is ready.
 */
function subscribe(batchId, handler) {
  let unsubscribeFn = () => {};
  let unsubscribed = false;

  kafkaClient
    .subscribe(topicFor(batchId), handler)
    .then((unsub) => {
      if (unsubscribed) {
        unsub(); // caller already unsubscribed before Kafka connected
      } else {
        unsubscribeFn = unsub;
      }
    })
    .catch((err) => {
      console.error(`Failed to subscribe to chat for batch ${batchId}:`, err.message);
    });

  return () => {
    unsubscribed = true;
    unsubscribeFn();
  };
}

module.exports = { publish, subscribe };
