import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100), // Spacing for floating navbar
      itemCount: 5,
      itemBuilder: (context, index) {
        final isOutgoing = index % 2 == 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: AppColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=u${index + 2}'),
              backgroundColor: AppColors.backgroundDark,
            ),
            title: Text(
              'User ${index + 2}',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textLight),
            ),
            subtitle: Row(
              children: [
                Icon(
                  isOutgoing ? Icons.call_made_rounded : Icons.call_received_rounded,
                  size: 14,
                  color: isOutgoing ? Colors.greenAccent : Colors.redAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  'Today, 12:0${index} PM',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textGrey),
                ),
              ],
            ),
            trailing: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                index % 3 == 0 ? Icons.videocam_rounded : Icons.call_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            onTap: () {},
          ),
        );
      },
    );
  }
}
