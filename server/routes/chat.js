/**
 * Chat Routes
 * 
 * All routes require JWT authentication via authMiddleware.
 * 
 * GET /api/chat/users          — List all registered users (for "New Chat" screen)
 * GET /api/chat/conversations  — Get current user's conversations with last message
 * GET /api/chat/messages/:roomId — Fetch message history for a room (last 50, paginated)
 */
const express = require('express');
const authMiddleware = require('../middleware/auth');
const User = require('../models/User');
const Message = require('../models/Message');
const UserStatus = require('../models/UserStatus');

const router = express.Router();

// All chat routes are protected
router.use(authMiddleware);

/**
 * GET /api/chat/users
 * 
 * Returns all registered users except the current user.
 * Used to populate the "New Chat" / contact list screen.
 * Each user includes their online/offline status.
 */
router.get('/users', async (req, res) => {
  try {
    // Fetch all users except the logged-in user, exclude password
    const users = await User.find({ _id: { $ne: req.user.userId } })
      .select('-password')
      .lean();

    // Fetch online status for each user
    const statuses = await UserStatus.find({
      userId: { $in: users.map(u => u._id) },
    }).lean();

    // Create a map of userId -> status for quick lookup
    const statusMap = {};
    statuses.forEach(s => {
      statusMap[s.userId.toString()] = s;
    });

    // Merge user data with their online status
    const usersWithStatus = users.map(user => ({
      id: user._id,
      name: user.name,
      email: user.email,
      avatarUrl: user.avatarUrl,
      about: user.about,
      isOnline: statusMap[user._id.toString()]?.isOnline || false,
      lastSeen: statusMap[user._id.toString()]?.lastSeen || null,
      publicKey: user.publicKey || '',
    }));

    res.json(usersWithStatus);
  } catch (err) {
    console.error('Get users error:', err.message);
    res.status(500).json({ error: 'Failed to fetch users.' });
  }
});

/**
 * GET /api/chat/conversations
 * 
 * Returns the current user's conversations — each conversation includes
 * the other user's info and the last message exchanged.
 * 
 * Strategy: Find all distinct roomIds the user has messages in,
 * then get the last message for each room, and the other user's info.
 */
router.get('/conversations', async (req, res) => {
  try {
    const userId = req.user.userId;

    // Find all distinct roomIds where this user has participated
    // Room IDs contain the user's ID as part of the string
    const messages = await Message.aggregate([
      {
        $match: {
          roomId: { $regex: userId },
        },
      },
      {
        $sort: { createdAt: -1 },
      },
      {
        // Group by roomId and take the last (most recent) message
        $group: {
          _id: '$roomId',
          lastMessage: { $first: '$$ROOT' },
        },
      },
      {
        $sort: { 'lastMessage.createdAt': -1 },
      },
    ]);

    // Build conversation list with the other user's info
    const conversations = [];
    for (const msg of messages) {
      const roomId = msg._id;
      const lastMessage = msg.lastMessage;

      // Extract the other user's ID from the roomId
      const userIds = roomId.split('_');
      const otherUserId = userIds.find(id => id !== userId);

      if (!otherUserId) continue;

      // Fetch the other user's profile
      const otherUser = await User.findById(otherUserId).select('-password').lean();
      if (!otherUser) continue;

      // Fetch online status
      const status = await UserStatus.findOne({ userId: otherUserId }).lean();

      // Count unread messages (messages not from this user that are 'sent')
      const unreadCount = await Message.countDocuments({
        roomId,
        senderId: { $ne: userId },
        status: 'sent',
      });

      conversations.push({
        roomId,
        user: {
          id: otherUser._id,
          name: otherUser.name,
          email: otherUser.email,
          avatarUrl: otherUser.avatarUrl,
          about: otherUser.about,
          isOnline: status?.isOnline || false,
          lastSeen: status?.lastSeen || null,
          publicKey: otherUser.publicKey || '',
        },
        lastMessage: {
          id: lastMessage._id,
          senderId: lastMessage.senderId,
          content: lastMessage.content,
          type: lastMessage.type,
          status: lastMessage.status,
          timestamp: lastMessage.createdAt,
          iv: lastMessage.iv,
          mac: lastMessage.mac,
          isEncrypted: lastMessage.isEncrypted || false,
        },
        unreadCount,
      });
    }

    res.json(conversations);
  } catch (err) {
    console.error('Get conversations error:', err.message);
    res.status(500).json({ error: 'Failed to fetch conversations.' });
  }
});

/**
 * GET /api/chat/messages/:roomId
 * 
 * Fetches message history for a specific room.
 * Returns the last 50 messages by default, supports pagination via ?before=<messageId>.
 * Messages are returned in chronological order (oldest first).
 */
router.get('/messages/:roomId', async (req, res) => {
  try {
    const { roomId } = req.params;
    const { before } = req.query; // Optional: for pagination
    const limit = 50;

    let query = { roomId };

    // If 'before' is provided, fetch messages older than that message
    if (before) {
      const refMessage = await Message.findById(before);
      if (refMessage) {
        query.createdAt = { $lt: refMessage.createdAt };
      }
    }

    const messages = await Message.find(query)
      .sort({ createdAt: -1 }) // newest first for limit
      .limit(limit)
      .lean();

    // Reverse to get chronological order (oldest first)
    messages.reverse();

    // Format response
    const formatted = messages.map(m => ({
      id: m._id,
      roomId: m.roomId,
      senderId: m.senderId,
      content: m.content,
      type: m.type,
      status: m.status,
      timestamp: m.createdAt,
      iv: m.iv,
      mac: m.mac,
      isEncrypted: m.isEncrypted || false,
    }));

    res.json(formatted);
  } catch (err) {
    console.error('Get messages error:', err.message);
    res.status(500).json({ error: 'Failed to fetch messages.' });
  }
});

module.exports = router;
