import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=u${index + 2}'),
          ),
          title: Text('User ${index + 2}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Row(
            children: [
              Icon(
                index % 2 == 0 ? Icons.call_made : Icons.call_received,
                size: 16,
                color: index % 2 == 0 ? AppColors.secondary : Colors.red,
              ),
              const SizedBox(width: 4),
              Text('Today, 12:00 PM'),
            ],
          ),
          trailing: Icon(
            index % 3 == 0 ? Icons.videocam : Icons.call,
            color: AppColors.primary,
          ),
          onTap: () {},
        );
      },
    );
  }
}
