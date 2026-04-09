const mongoose = require('mongoose');

const groupSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Group name is required'],
    trim: true,
  },
  description: {
    type: String,
    default: '',
  },
  avatarUrl: {
    type: String,
    default: '',
  },
  creatorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  members: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    isAdmin: {
      type: Boolean,
      default: false,
    },
    // The group key encrypted with this user's public key
    encryptedKey: {
      type: String,
      required: true,
    },
  }],
}, {
  timestamps: true,
});

module.exports = mongoose.model('Group', groupSchema);
