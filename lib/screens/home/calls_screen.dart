import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 5,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 76, color: AppColors.dividerLight),
      itemBuilder: (context, index) {
        final isOutgoing = index % 2 == 0;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            radius: 26,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=u${index + 2}'),
            backgroundColor: AppColors.surfaceVariant,
          ),
          title: Text(
            'User ${index + 2}',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.snapBlack),
          ),
          subtitle: Row(
            children: [
              Icon(
                isOutgoing ? Icons.call_made_rounded : Icons.call_received_rounded,
                size: 14,
                color: isOutgoing ? AppColors.online : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                'Today, 12:0${index} PM',
                style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textGrey),
              ),
            ],
          ),
          trailing: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Icon(
              index % 3 == 0 ? Icons.videocam_rounded : Icons.call_rounded,
              color: AppColors.snapBlack,
              size: 20,
            ),
          ),
          onTap: () {},
        );
      },
    );
  }
}
