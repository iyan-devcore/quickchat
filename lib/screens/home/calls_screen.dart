import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/call_model.dart';
import '../../models/user_model.dart';
import '../../providers/call_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_colors.dart';
import '../chat/call_screen.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh on each visit in case there are new logs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallProvider>().loadCalls();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<UserProvider>().currentUser?.id ?? '';

    return Consumer<CallProvider>(
      builder: (context, callProvider, _) {
        if (callProvider.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (callProvider.error != null) {
          return _buildErrorState(callProvider);
        }

        if (callProvider.calls.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: callProvider.loadCalls,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: callProvider.calls.length,
            itemBuilder: (context, index) {
              final call = callProvider.calls[index];
              return _CallTile(call: call, currentUserId: currentUserId);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.call_rounded, size: 44, color: AppColors.textGrey),
          ),
          const SizedBox(height: 20),
          Text(
            'No call history yet',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your calls will appear here',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CallProvider callProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.textGrey),
          const SizedBox(height: 16),
          Text(
            'Could not load calls',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: callProvider.loadCalls,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _CallTile extends StatelessWidget {
  final CallLog call;
  final String currentUserId;

  const _CallTile({required this.call, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final isOutgoing = call.isOutgoing(currentUserId);
    final otherName = isOutgoing ? call.receiverName : call.callerName;
    final initial = otherName.isNotEmpty ? otherName[0].toUpperCase() : '?';

    // Icon + colour based on call status & direction
    IconData directionIcon;
    Color directionColor;
    switch (call.status) {
      case CallStatus.missed:
        directionIcon = Icons.call_missed_rounded;
        directionColor = Colors.redAccent;
        break;
      case CallStatus.rejected:
        directionIcon = Icons.call_missed_outgoing_rounded;
        directionColor = Colors.orangeAccent;
        break;
      case CallStatus.answered:
        directionIcon = isOutgoing
            ? Icons.call_made_rounded
            : Icons.call_received_rounded;
        directionColor = Colors.greenAccent;
        break;
    }

    final timeLabel = _formatTime(call.startedAt);
    final durationLabel = call.formattedDuration();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primary.withOpacity(0.15),
          child: Text(
            initial,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          otherName.isNotEmpty ? otherName : 'Unknown',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textLight,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(directionIcon, size: 14, color: directionColor),
            const SizedBox(width: 6),
            Text(
              timeLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textGrey,
              ),
            ),
            if (durationLabel.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                '· $durationLabel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ],
        ),
        trailing: _buildCallBackButton(context, call, currentUserId),
        onTap: () => _showCallDetails(context, call, currentUserId, otherName),
      ),
    );
  }

  Widget _buildCallBackButton(BuildContext context, CallLog call, String currentUserId) {
    final isVideo = call.type == CallType.video;
    final receiverId = call.isOutgoing(currentUserId) ? call.receiverId : call.callerId;
    final otherName = call.isOutgoing(currentUserId) ? call.receiverName : call.callerName;

    return GestureDetector(
      onTap: () => _placeCall(context, receiverId, otherName, isVideo, currentUserId),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          isVideo ? Icons.videocam_rounded : Icons.call_rounded,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }

  void _placeCall(BuildContext context, String receiverId, String receiverName,
      bool isVideo, String currentUserId) {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;
    if (currentUser == null) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CallScreen(
        callerId: currentUserId,
        callerName: currentUser.name,
        receiverId: receiverId,
        isVideo: isVideo,
        isIncoming: false,
      ),
    ));
  }

  void _showCallDetails(BuildContext context, CallLog call, String currentUserId, String otherName) {
    final isVideo = call.type == CallType.video;
    final statusStr = call.status == CallStatus.answered
        ? 'Answered'
        : call.status == CallStatus.rejected
            ? 'Declined'
            : 'Missed';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              otherName.isNotEmpty ? otherName : 'Unknown',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$statusStr · ${isVideo ? 'Video' : 'Voice'} · ${_formatTime(call.startedAt)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
            ),
            if (call.formattedDuration().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Duration: ${call.formattedDuration()}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _DetailButton(
                    icon: Icons.call_rounded,
                    label: 'Voice Call',
                    onTap: () {
                      Navigator.pop(context);
                      final receiverId = call.isOutgoing(currentUserId)
                          ? call.receiverId
                          : call.callerId;
                      _placeCall(context, receiverId, otherName, false, currentUserId);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailButton(
                    icon: Icons.videocam_rounded,
                    label: 'Video Call',
                    onTap: () {
                      Navigator.pop(context);
                      final receiverId = call.isOutgoing(currentUserId)
                          ? call.receiverId
                          : call.callerId;
                      _placeCall(context, receiverId, otherName, true, currentUserId);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return 'Today, $hour:$minute $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}

class _DetailButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DetailButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
