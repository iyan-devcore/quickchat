/**
 * Authentication Routes
 * 
 * POST /api/auth/register — Create a new user account
 * POST /api/auth/login    — Authenticate and receive a JWT token
 * 
 * Both endpoints return the user object (without password) and a JWT token.
 * The token should be stored client-side and sent with subsequent requests.
 */
const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const UserStatus = require('../models/UserStatus');
const authMiddleware = require('../middleware/auth');
const { sendWelcomeEmail } = require('../utils/email');

const router = express.Router();

/**
 * Generate a JWT token for the given user ID.
 * Token expires in 30 days to minimize re-login friction.
 */
function generateToken(userId) {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '30d' });
}

/**
 * POST /api/auth/register
 * 
 * Body: { name, email, password }
 * Returns: { user, token }
 */
router.post('/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;

    // Validate required fields
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email, and password are required.' });
    }

    // Check if email is already registered
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ error: 'Email is already registered.' });
    }

    // Create new user (password is hashed via pre-save hook)
    const user = new User({
      name,
      email: email.toLowerCase(),
      password,
      avatarUrl: `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=008069&color=fff&size=150`,
    });
    await user.save();

    // Initialize user status record
    await UserStatus.create({ userId: user._id, isOnline: false });

    // Generate token
    const token = generateToken(user._id);

    // Send welcome email asynchronously so it doesn't delay the response
    sendWelcomeEmail(user.email, user.name);

    // Return user data (exclude password) and token
    res.status(201).json({
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        avatarUrl: user.avatarUrl,
        about: user.about,
        publicKey: user.publicKey || '',
      },
      token,
    });
  } catch (err) {
    console.error('Register error:', err.message);
    res.status(500).json({ error: 'Server error during registration.' });
  }
});

/**
 * POST /api/auth/login
 * 
 * Body: { email, password }
 * Returns: { user, token }
 */
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate required fields
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }

    // Find user by email
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    // Verify password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    // Generate token
    const token = generateToken(user._id);

    // Return user data and token
    res.json({
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        avatarUrl: user.avatarUrl,
        about: user.about,
        publicKey: user.publicKey || '',
      },
      token,
    });
  } catch (err) {
    console.error('Login error:', err.message);
    res.status(500).json({ error: 'Server error during login.' });
  }
});

/**
 * POST /api/auth/public-key
 *
 * Update user's public key for E2E encryption.
 */
router.post('/public-key', authMiddleware, async (req, res) => {
  try {
    const { publicKey } = req.body;
    if (!publicKey) {
      return res.status(400).json({ error: 'Public key is required.' });
    }

    await User.findByIdAndUpdate(req.user.userId, { publicKey });
    res.json({ message: 'Public key updated successfully.' });
  } catch (err) {
    console.error('Update public key error:', err.message);
    res.status(500).json({ error: 'Failed to update public key.' });
  }
});

/**
 * PATCH /api/auth/profile
 *
 * Update name, about, and/or avatarUrl for the authenticated user.
 * Body: { name?, about?, avatarUrl? }
 */
router.patch('/profile', authMiddleware, async (req, res) => {
  try {
    const { name, about, avatarUrl } = req.body;
    const updates = {};
    if (name)      updates.name      = name;
    if (about !== undefined) updates.about = about;
    if (avatarUrl) updates.avatarUrl = avatarUrl;

    const user = await User.findByIdAndUpdate(
      req.user.userId,
      updates,
      { new: true }
    );

    if (!user) return res.status(404).json({ error: 'User not found.' });

    res.json({
      id: user._id,
      name: user.name,
      email: user.email,
      avatarUrl: user.avatarUrl,
      about: user.about,
      publicKey: user.publicKey || '',
    });
  } catch (err) {
    console.error('Update profile error:', err.message);
    res.status(500).json({ error: 'Failed to update profile.' });
  }
});

module.exports = router;
