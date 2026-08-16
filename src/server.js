require('dotenv').config();
const http = require('http');
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const { WebSocketServer } = require('ws');

const authRoutes = require('./routes/auth.routes');
const batchRoutes = require('./routes/batch.routes');
const sellerRoutes = require('./routes/seller.routes');
const kycRoutes = require('./routes/kyc.routes');
const notificationRoutes = require('./routes/notification.routes');
const chatEvents = require('./services/chat.events');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.use('/auth', authRoutes);
app.use('/batches', batchRoutes);
app.use('/sellers', sellerRoutes);
app.use('/kyc', kycRoutes);
app.use('/notifications', notificationRoutes);

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'internal server error' });
});

const server = http.createServer(app);

// Real-time chat delivery. Client connects to:
//   ws://<host>/ws/batches/:batchId/messages?token=<jwt>
// and receives each new message as JSON the moment it's posted, instead of
// polling GET /batches/:batchId/messages. Stands in for the per-batch Kafka
// topic from the Q8 decision - see src/services/chat.events.js.
const wss = new WebSocketServer({ noServer: true });

server.on('upgrade', (req, socket, head) => {
  const match = req.url.match(/^\/ws\/batches\/([^/]+)\/messages\?token=(.+)$/);
  if (!match) {
    socket.destroy();
    return;
  }
  const [, batchId, token] = match;

  try {
    jwt.verify(token, process.env.JWT_SECRET);
  } catch (err) {
    socket.destroy();
    return;
  }

  wss.handleUpgrade(req, socket, head, (ws) => {
    const unsubscribe = chatEvents.subscribe(batchId, (message) => {
      if (ws.readyState === ws.OPEN) ws.send(JSON.stringify(message));
    });
    ws.on('close', unsubscribe);
  });
});

const PORT = process.env.PORT || 4000;
server.listen(PORT, () => {
  console.log(`GroFresh backend listening on port ${PORT}`);
});
