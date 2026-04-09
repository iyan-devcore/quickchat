const express = require('express');
const Group = require('../models/Group');
const Message = require('../models/Message');
const User = require('../models/User');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

router.use(authMiddleware);

/**
 * POST /api/groups
 * Create a new encrypted group.
 * Body: { name, members, description }
 * members: [{ userId, encryptedKey }]
 */
router.post('/', async (req, res) => {
  try {
    const { name, members, description } = req.body;

    if (!name || !members || members.length === 0) {
      return res.status(400).json({ error: 'Group name and members are required.' });
    }

    // Add creator as an admin member
    // The creator must have include their own encryptedKey in the members list
    const group = new Group({
      name,
      description,
      creatorId: req.user.userId,
      members,
      avatarUrl: `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=random&color=fff&size=150`,
    });

    await group.save();
    res.status(201).json(group);
  } catch (err) {
    console.error('Create group error:', err.message);
    res.status(500).json({ error: 'Failed to create group.' });
  }
});

/**
 * GET /api/groups
 * Get all groups the current user is a member of.
 */
router.get('/', async (req, res) => {
  try {
    const groups = await Group.find({ 'members.userId': req.user.userId })
      .populate('members.userId', 'name email avatarUrl publicKey')
      .lean();

    // Map to a cleaner format for the frontend
    const formattedGroups = groups.map(group => {
      // Find my encrypted key for this group
      const myMemberInfo = group.members.find(m => m.userId._id.toString() === req.user.userId);
      
      return {
        id: group._id,
        name: group.name,
        description: group.description,
        avatarUrl: group.avatarUrl,
        creatorId: group.creatorId,
        myEncryptedKey: myMemberInfo ? myMemberInfo.encryptedKey : null,
        memberIds: group.members.map(m => m.userId._id),
        members: group.members.map(m => ({
          id: m.userId._id,
          name: m.userId.name,
          publicKey: m.userId.publicKey,
          isAdmin: m.isAdmin
        })),
        createdAt: group.createdAt
      };
    });

    res.json(formattedGroups);
  } catch (err) {
    console.error('Get groups error:', err.message);
    res.status(500).json({ error: 'Failed to fetch groups.' });
  }
});

/**
 * GET /api/groups/:groupId
 * Get details of a specific group.
 */
router.get('/:groupId', async (req, res) => {
  try {
    const group = await Group.findById(req.params.groupId)
      .populate('members.userId', 'name email avatarUrl publicKey')
      .lean();

    if (!group) return res.status(404).json({ error: 'Group not found.' });

    // Verify user is a member
    const isMember = group.members.some(m => m.userId._id.toString() === req.user.userId);
    if (!isMember) return res.status(403).json({ error: 'Access denied.' });

    const myMemberInfo = group.members.find(m => m.userId._id.toString() === req.user.userId);

    res.json({
      id: group._id,
      name: group.name,
      description: group.description,
      avatarUrl: group.avatarUrl,
      creatorId: group.creatorId,
      myEncryptedKey: myMemberInfo ? myMemberInfo.encryptedKey : null,
      members: group.members.map(m => ({
        id: m.userId._id,
        name: m.userId.name,
        publicKey: m.userId.publicKey,
        isAdmin: m.isAdmin
      })),
    });
  } catch (err) {
    console.error('Get group error:', err.message);
    res.status(500).json({ error: 'Failed to fetch group details.' });
  }
});

module.exports = router;
