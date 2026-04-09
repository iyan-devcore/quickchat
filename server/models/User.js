/**
 * User Model — MongoDB Schema
 * 
 * Stores registered user accounts with hashed passwords.
 * The password is automatically hashed before saving via a pre-save hook.
 */
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: 6,
  },
  avatarUrl: {
    type: String,
    default: '',
  },
  about: {
    type: String,
    default: 'Hey there! I am using QuickChat.',
  },
  publicKey: {
    type: String,
    default: '',
  },
}, {
  timestamps: true, // adds createdAt, updatedAt
});

/**
 * Pre-save hook: hash password before storing in the database.
 * Only re-hashes if the password field has been modified (not on every save).
 */
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(12);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

/**
 * Instance method: compare a candidate password against the stored hash.
 * Used during login to validate credentials.
 */
userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
