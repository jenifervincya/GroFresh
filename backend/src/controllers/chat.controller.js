const chatModel = require('../models/chat.model');
const chatEvents = require('../services/chat.events');
const batchModel = require('../models/batch.model');

// GET /batches/:batchId/messages
async function listMessages(req, res) {
  const batch = await batchModel.getById(req.params.batchId);
  if (!batch) return res.status(404).json({ error: 'batch not found' });

  const messages = await chatModel.listMessages(req.params.batchId);
  return res.json(messages);
}

// POST /batches/:batchId/messages
// { text } -> single message object
async function postMessage(req, res) {
  const { text } = req.body;
  if (!text) return res.status(400).json({ error: 'text is required' });

  const batch = await batchModel.getById(req.params.batchId);
  if (!batch) return res.status(404).json({ error: 'batch not found' });

  const message = await chatModel.postMessage(req.params.batchId, req.userId, text);

  // Real-time fan-out to anyone subscribed to this batch's chat (websocket
  // clients in server.js). This is the app-facing equivalent of publishing
  // to the per-batch Kafka topic from the Q8 decision.
  chatEvents.publish(req.params.batchId, message);

  return res.status(201).json(message);
}

module.exports = { listMessages, postMessage };
