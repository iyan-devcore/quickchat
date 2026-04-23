import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_colors.dart';

/// Stories/Status screen — Snapchat light theme.
class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;

    return ListView(
      children: [
        // My story
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'MY STORY',
            style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textGrey, letterSpacing: 0.8),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: AppColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: user != null ? NetworkImage(user.avatarUrl) : null,
                      backgroundColor: AppColors.surfaceVariant,
                      child: user == null ? const Icon(Icons.person, color: AppColors.textGrey) : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.add_rounded, size: 16, color: AppColors.snapBlack),
                  ),
                ),
              ],
            ),
            title: Text('My Story', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.snapBlack)),
            subtitle: Text('Tap to add a story update', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textGrey)),
            onTap: () {},
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'RECENT UPDATES',
            style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textGrey, letterSpacing: 0.8),
          ),
        ),

        ...List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: AppColors.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=u${index + 2}'),
                  ),
                ),
              ),
              title: Text('User ${index + 2}', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.snapBlack)),
              subtitle: Text('Today, ${10 + index}:30 AM', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textGrey)),
              onTap: () {},
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
