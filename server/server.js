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
const CallLog = require('./models/CallLog');

// Import routes
const authRoutes = require('./routes/auth');
const chatRoutes = require('./routes/chat');
const groupRoutes = require('./routes/group');
const uploadRoutes = require('./routes/upload');
const callRoutes = require('./routes/calls');
const path = require('path');

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
app.use('/api/upload', uploadRoutes);
app.use('/api/calls', callRoutes);

// Server uploaded files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

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
      const { roomId, content, type = 'text', iv, mac, isEncrypted = false, isGroup = false, replyTo = null, fileName, fileSize } = data;

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
        replyTo,
        fileName,
        fileSize,
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
        replyTo: message.replyTo ? message.replyTo.toString() : null,
        fileName: message.fileName,
        fileSize: message.fileSize,
        reactions: [],
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
  // Event: delete_message
  // ─────────────────────────────────────────
  socket.on('delete_message', async (data) => {
    try {
      const { messageId, roomId } = data;
      const message = await Message.findOne({ _id: messageId, senderId: userId });
      if (message && !message.isDeleted) {
        message.isDeleted = true;
        message.content = 'This message was deleted';
        message.isEncrypted = false;
        await message.save();
        io.to(roomId).emit('message_deleted', { messageId, roomId });
      }
    } catch (err) {
      console.error('Delete message error:', err.message);
    }
  });

  // ─────────────────────────────────────────
  // Event: edit_message
  // ─────────────────────────────────────────
  socket.on('edit_message', async (data) => {
    try {
      const { messageId, roomId, newContent, iv, mac } = data;
      const message = await Message.findOne({ _id: messageId, senderId: userId, isDeleted: false });
      if (message) {
        message.content = newContent;
        message.isEdited = true;
        if (iv) message.iv = iv;
        if (mac) message.mac = mac;
        await message.save();
        
        const updatePayload = {
          messageId,
          roomId,
          newContent,
          iv: message.iv,
          mac: message.mac,
        };
        io.to(roomId).emit('message_edited', updatePayload);
      }
    } catch (err) {
      console.error('Edit message error:', err.message);
    }
  });

  // ─────────────────────────────────────────
  // Event: toggle_reaction
  // ─────────────────────────────────────────
  socket.on('toggle_reaction', async (data) => {
    try {
      const { messageId, roomId, emoji } = data;
      const message = await Message.findById(messageId);
      if (!message || message.isDeleted) return;

      const existingReactionIndex = message.reactions.findIndex(
        r => r.userId.toString() === userId
      );

      if (existingReactionIndex !== -1) {
        if (message.reactions[existingReactionIndex].emoji === emoji) {
          // Remove reaction if clicking the same emoji again
          message.reactions.splice(existingReactionIndex, 1);
        } else {
          // Change reaction
          message.reactions[existingReactionIndex].emoji = emoji;
        }
      } else {
        // Add new reaction
        message.reactions.push({ userId, emoji });
      }

      await message.save();

      io.to(roomId).emit('message_reaction_updated', {
        messageId,
        roomId,
        reactions: message.reactions
      });
    } catch (err) {
      console.error('Toggle reaction error:', err.message);
    }
  });

  // ─────────────────────────────────────────
  // Event: mark_room_read
  // ─────────────────────────────────────────
  socket.on('mark_room_read', async (data) => {
    try {
      const { roomId } = data;
      await Message.updateMany(
        { roomId, senderId: { $ne: userId }, status: { $ne: 'read' } },
        { status: 'read' }
      );
      socket.to(roomId).emit('room_messages_read', { roomId, byUserId: userId });
    } catch (err) {
      console.error('Mark room read error:', err.message);
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
  // WebRTC Signaling Events for Calling
  // ─────────────────────────────────────────

  // 1. Initiate Call
  socket.on('call_user', async (data) => {
    try {
      const { userToCall, signalData, callerName, isVideo } = data;
      // Find callee's socket
      const userStatus = await UserStatus.findOne({ userId: userToCall });
      if (userStatus && userStatus.isOnline && userStatus.socketId) {
        io.to(userStatus.socketId).emit('incoming_call', {
          from: userId,
          callerName,
          signal: signalData,
          isVideo,
        });
      } else {
        socket.emit('call_failed', { reason: 'User is offline' });
      }
    } catch (err) {
      console.error('Call user error:', err.message);
    }
  });

  // 2. Answer Call
  socket.on('answer_call', async (data) => {
    try {
      const { to, signal } = data; // 'to' is caller's userId
      const userStatus = await UserStatus.findOne({ userId: to });
      if (userStatus && userStatus.isOnline && userStatus.socketId) {
        io.to(userStatus.socketId).emit('call_answered', {
          signal,
          from: userId,
        });
      }
    } catch (err) {
      console.error('Answer call error:', err.message);
    }
  });

  // 3. ICE Candidate Exchange
  socket.on('ice_candidate', async (data) => {
    try {
      const { to, candidate } = data;
      const userStatus = await UserStatus.findOne({ userId: to });
      if (userStatus && userStatus.isOnline && userStatus.socketId) {
        io.to(userStatus.socketId).emit('ice_candidate', {
          candidate,
          from: userId,
        });
      }
    } catch (err) {
      console.error('ICE candidate error:', err.message);
    }
  });

  // 4. End Call
  socket.on('end_call', async (data) => {
    try {
      const { to } = data;
      const userStatus = await UserStatus.findOne({ userId: to });
      if (userStatus && userStatus.isOnline && userStatus.socketId) {
        io.to(userStatus.socketId).emit('call_ended', { from: userId });
      }
    } catch (err) {
      console.error('End call error:', err.message);
    }
  });

  // 5. Reject Call
  socket.on('reject_call', async (data) => {
    try {
      const { to } = data;
      const userStatus = await UserStatus.findOne({ userId: to });
      if (userStatus && userStatus.isOnline && userStatus.socketId) {
        io.to(userStatus.socketId).emit('call_rejected', { from: userId });
      }
    } catch (err) {
      console.error('Reject call error:', err.message);
    }
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
