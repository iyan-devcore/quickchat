/**
 * QuickChat Server — Main Entry Point
 * 
 * Express + Socket.io + MongoDB server that provides:
 * 1. REST API for authentication and chat history
 * 2. Real-time WebSocket communication for live messaging
 * 3. Online/offline user status tracking
 * 
 * Architecture:
 * - HTTP server wraps Express for Socket.io compatibility
 * - Socket.io authenticates connections using JWT tokens
 * - Messages are ALWAYS saved to MongoDB first, then broadcast
 *   (this ensures offline users never miss messages)
 */
require('dotenv').config();

const express = require('express');
const http = require('http');
const cors = require('cors');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const { Server } = require('socket.io');

// Import models
const Message = require('./models/Message');
const UserStatus = require('./models/UserStatus');

// Import routes
const authRoutes = require('./routes/auth');
const chatRoutes = require('./routes/chat');
const groupRoutes = require('./routes/group');

// ─────────────────────────────────────────────
// Express App Setup
// ─────────────────────────────────────────────
const app = express();

// Middleware
app.use(cors({
  origin: '*', // Allow Flutter web from any origin during development
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json());

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/groups', groupRoutes);

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ status: 'QuickChat server is running 🚀' });
});

// ─────────────────────────────────────────────
// HTTP Server & Socket.io Setup
// ─────────────────────────────────────────────
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*', // Allow all origins during development
    methods: ['GET', 'POST'],
  },
});

/**
 * Socket.io Authentication Middleware
 * 
 * Validates the JWT token sent during the WebSocket handshake.
 * The token is expected in socket.handshake.auth.token.
 * If valid, the decoded userId is attached to socket.userId.
 */
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  if (!token) {
    return next(new Error('Authentication error: No token provided'));
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    socket.userId = decoded.userId;
    next();
  } catch (err) {
    return next(new Error('Authentication error: Invalid token'));
  }
});

// ─────────────────────────────────────────────
// Socket.io Event Handlers
// ─────────────────────────────────────────────
io.on('connection', async (socket) => {
  const userId = socket.userId;
  console.log(`✅ User connected: ${userId} (socket: ${socket.id})`);

  // ── Mark user as ONLINE ──
  await UserStatus.findOneAndUpdate(
    { userId },
    { isOnline: true, socketId: socket.id, lastSeen: new Date() },
    { upsert: true, new: true }
  );

  // Broadcast to all connected clients that this user is online
  socket.broadcast.emit('user_online', { userId });

  // ─────────────────────────────────────────
  // Event: join_room
  // Client joins a specific chat room to receive messages
  // ─────────────────────────────────────────
  socket.on('join_room', (data) => {
    const { roomId } = data;
    socket.join(roomId);
    console.log(`📌 User ${userId} joined room: ${roomId}`);
  });

  // ─────────────────────────────────────────
  // Event: send_message
  // Client sends a message — save to DB first, then broadcast
  // ─────────────────────────────────────────
  socket.on('send_message', async (data) => {
    try {
      const { roomId, content, type = 'text', iv, mac, isEncrypted = false, isGroup = false } = data;

      // 1. Save message to MongoDB
      const message = new Message({
        roomId,
        senderId: userId,
        content,
        type,
        status: 'sent',
        iv,
        mac,
        isEncrypted,
        isGroup,
      });
      await message.save();

      // 2. Build the response payload
      const messagePayload = {
        id: message._id.toString(),
        roomId: message.roomId,
        senderId: message.senderId.toString(),
        content: message.content,
        type: message.type,
        status: message.status,
        timestamp: message.createdAt.toISOString(),
        iv: message.iv,
        mac: message.mac,
        isEncrypted: message.isEncrypted,
        isGroup: message.isGroup,
      };

      // 3. Broadcast to all users in the room
      io.to(roomId).emit('receive_message', messagePayload);

      console.log(`💬 Message in ${roomId}: "${content.substring(0, 30)}..."`);
    } catch (err) {
      console.error('Send message error:', err.message);
      socket.emit('error_message', { error: 'Failed to send message.' });
    }
  });

  // ─────────────────────────────────────────
  // Event: typing
  // Broadcasts typing indicator to the room
  // ─────────────────────────────────────────
  socket.on('typing', (data) => {
    const { roomId, isTyping } = data;
    socket.to(roomId).emit('user_typing', { userId, isTyping });
  });

  // ─────────────────────────────────────────
  // Event: disconnect
  // Mark user offline and broadcast status change
  // ─────────────────────────────────────────
  socket.on('disconnect', async () => {
    console.log(`❌ User disconnected: ${userId} (socket: ${socket.id})`);

    // Mark user as OFFLINE
    const lastSeen = new Date();
    await UserStatus.findOneAndUpdate(
      { userId },
      { isOnline: false, lastSeen: lastSeen, socketId: null }
    );

    // Broadcast to all clients that this user went offline
    socket.broadcast.emit('user_offline', { userId, lastSeen: lastSeen.toISOString() });
  });
});

// ─────────────────────────────────────────────
// MongoDB Connection & Server Start
// ─────────────────────────────────────────────
const PORT = process.env.PORT || 5000;

mongoose
  .connect(process.env.MONGO_URI)
  .then(() => {
    console.log('📦 Connected to MongoDB');
    server.listen(PORT, () => {
      console.log(`🚀 QuickChat server running on http://localhost:${PORT}`);
    });
  })
  .catch((err) => {
    console.error('❌ MongoDB connection error:', err.message);
    process.exit(1);
  });
