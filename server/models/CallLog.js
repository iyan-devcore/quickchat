const mongoose = require('mongoose');

/**
 * CallLog — stores a record for every call attempt.
 *
 * Fields:
 *  callerId    — userId of the person who initiated the call
 *  receiverId  — userId of the person who was called
 *  callerName  — display name of the caller (denormalised for fast reads)
 *  receiverName— display name of the receiver
 *  isVideo     — true for video calls, false for audio
 *  status      — 'answered' | 'missed' | 'rejected'
 *  startedAt   — when the call was initiated (createdAt)
 *  endedAt     — when the call ended (null for missed/rejected)
 *  duration    — call duration in seconds (0 for missed/rejected)
 */
const callLogSchema = new mongoose.Schema(
  {
    callerId:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    receiverId:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    callerName:  { type: String, default: '' },
    receiverName:{ type: String, default: '' },
    isVideo:     { type: Boolean, default: false },
    status:      { type: String, enum: ['answered', 'missed', 'rejected'], default: 'missed' },
    startedAt:   { type: Date, default: Date.now },
    endedAt:     { type: Date, default: null },
    duration:    { type: Number, default: 0 }, // seconds
  },
  { timestamps: true }
);

// Index so fetching a user's call history is fast
callLogSchema.index({ callerId: 1, createdAt: -1 });
callLogSchema.index({ receiverId: 1, createdAt: -1 });

module.exports = mongoose.model('CallLog', callLogSchema);
