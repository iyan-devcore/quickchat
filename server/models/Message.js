/**
 * Message Model — MongoDB Schema
 * 
 * Stores all chat messages. Each message belongs to a "room" which is
 * a deterministic ID derived from the two participants' user IDs.
 * 
 * Room ID format: sorted join of two user IDs, e.g. "abc123_def456"
 * This ensures the same room ID regardless of who initiates the conversation.
 * 
 * Messages are persisted FIRST to MongoDB, THEN broadcast via Socket.io.
 * This guarantees offline users can retrieve messages on next login.
 */
const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  roomId: {
    type: String,
    required: true,
    index: true, // indexed for fast query of room history
  },
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  content: {
    type: String,
    required: true,
  },
  iv: {
    type: String,
  },
  mac: {
    type: String,
  },
  isEncrypted: {
    type: Boolean,
    default: false,
  },
  isGroup: {
    type: Boolean,
    default: false,
  },
  type: {
    type: String,
    enum: ['text', 'image', 'audio', 'video'],
    default: 'text',
  },
  status: {
    type: String,
    enum: ['sent', 'delivered', 'read'],
    default: 'sent',
  },
}, {
  timestamps: true, // createdAt serves as the message timestamp
});

module.exports = mongoose.model('Message', messageSchema);
