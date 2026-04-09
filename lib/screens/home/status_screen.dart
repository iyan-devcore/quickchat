import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_colors.dart';

/// Status/Updates screen — shows user statuses.
/// Currently uses placeholder data for the status list
/// while the main user avatar comes from the authenticated user.
class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Provider.of<UserProvider>(context).currentUser;
    
    return ListView(
      children: [
        ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: user != null
                    ? NetworkImage(user.avatarUrl)
                    : null,
                child: user == null ? const Icon(Icons.person) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                  ),
                  child: const Icon(Icons.add, size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
          title: const Text('My Status', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Tap to add status update'),
          onTap: () {},
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Recent updates',
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: isDark ? AppColors.textGrey : Colors.grey[600],
            ),
          ),
        ),
        // Placeholder statuses
        ...List.generate(3, (index) {
          return ListTile(
            leading: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.secondary, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=u${index + 2}'),
                ),
              ),
            ),
            title: Text('User ${index + 2}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Today, 10:${30 + index} AM'),
            onTap: () {},
          );
        }),
      ],
    );
  }
}
