const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const CallLog = require('../models/CallLog');

// ── Auth middleware ──────────────────────────────────────────
function auth(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// ── POST /api/calls ─────────────────────────────────────────
// Save a new call log (called by Flutter when a call ends/is rejected)
router.post('/', auth, async (req, res) => {
  try {
    const { receiverId, callerName, receiverName, isVideo, status, startedAt, endedAt, duration } = req.body;

    const log = await CallLog.create({
      callerId:     req.userId,
      receiverId,
      callerName:   callerName  || '',
      receiverName: receiverName|| '',
      isVideo:      isVideo     || false,
      status:       status      || 'missed',
      startedAt:    startedAt   ? new Date(startedAt) : new Date(),
      endedAt:      endedAt     ? new Date(endedAt)   : null,
      duration:     duration    || 0,
    });

    res.status(201).json(log);
  } catch (err) {
    console.error('Save call error:', err.message);
    res.status(500).json({ error: 'Failed to save call log' });
  }
});

// ── GET /api/calls ──────────────────────────────────────────
// Return the last 50 call logs for the authenticated user (newest first)
router.get('/', auth, async (req, res) => {
  try {
    const uid = req.userId;

    const logs = await CallLog.find({
      $or: [{ callerId: uid }, { receiverId: uid }],
    })
      .sort({ createdAt: -1 })
      .limit(50)
      .lean();

    // Shape response so Flutter can use it directly
    const shaped = logs.map((l) => ({
      id:           l._id.toString(),
      callerId:     l.callerId.toString(),
      receiverId:   l.receiverId.toString(),
      callerName:   l.callerName,
      receiverName: l.receiverName,
      isVideo:      l.isVideo,
      status:       l.status,
      startedAt:    l.startedAt?.toISOString() ?? l.createdAt.toISOString(),
      endedAt:      l.endedAt?.toISOString() ?? null,
      duration:     l.duration,
    }));

    res.json(shaped);
  } catch (err) {
    console.error('Get calls error:', err.message);
    res.status(500).json({ error: 'Failed to fetch call logs' });
  }
});

module.exports = router;
