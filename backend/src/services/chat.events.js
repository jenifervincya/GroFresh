const { EventEmitter } = require('events');

/**
 * Q8 decision sent to Tamil: a Kafka topic per batch instead of polling.
 *
 * This EventEmitter is the in-process stand-in for that Kafka topic while
 * a broker isn't provisioned yet. Every place that would publish/consume a
 * Kafka message for chat instead emits/listens here, so swapping in real
 * Kafka later (kafkajs producer per batch topic, consumer group per
 * connected client) only touches this file and the websocket layer in
 * server.js - REST/controller code doesn't change.
 */
const chatBus = new EventEmitter();
chatBus.setMaxListeners(0);

function publish(batchId, message) {
  chatBus.emit(`batch:${batchId}`, message);
}

function subscribe(batchId, handler) {
  const event = `batch:${batchId}`;
  chatBus.on(event, handler);
  return () => chatBus.off(event, handler);
}

module.exports = { publish, subscribe };
