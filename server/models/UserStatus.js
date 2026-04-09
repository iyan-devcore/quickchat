/**
 * UserStatus Model — MongoDB Schema
 * 
 * Tracks each user's online/offline state and their current Socket.io
 * connection ID. Updated on every connect/disconnect event.
 * 
 * - When a user connects via Socket.io, their status is set to online
 *   and their socketId is stored.
 * - When they disconnect, isOnline is set to false and lastSeen is updated.
 */
const mongoose = require('mongoose');

const userStatusSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    unique: true,
    required: true,
  },
  isOnline: {
    type: Boolean,
    default: false,
  },
  lastSeen: {
    type: Date,
    default: Date.now,
  },
  socketId: {
    type: String,
    default: null,
  },
});

module.exports = mongoose.model('UserStatus', userStatusSchema);
