import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  bool _isEditingName = false;
  bool _isEditingAbout = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _aboutController.text = user.about;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    Provider.of<UserProvider>(context, listen: false).updateProfile(
      _nameController.text,
      _aboutController.text,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('User not found')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundImage: NetworkImage(user.avatarUrl),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.textGrey),
              title: const Text(
                'Name',
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
              subtitle: _isEditingName
                  ? TextField(
                      controller: _nameController,
                      autofocus: true,
                      onSubmitted: (_) {
                        setState(() => _isEditingName = false);
                        _saveProfile();
                      },
                    )
                  : Text(
                      user.name,
                      style: const TextStyle(fontSize: 16),
                    ),
              trailing: IconButton(
                icon: Icon(_isEditingName ? Icons.check : Icons.edit, color: AppColors.primary),
                onPressed: () {
                  if (_isEditingName) {
                    _saveProfile();
                  }
                  setState(() => _isEditingName = !_isEditingName);
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.textGrey),
              title: const Text(
                'About',
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
              subtitle: _isEditingAbout
                  ? TextField(
                      controller: _aboutController,
                      autofocus: true,
                      onSubmitted: (_) {
                        setState(() => _isEditingAbout = false);
                        _saveProfile();
                      },
                    )
                  : Text(
                      user.about,
                      style: const TextStyle(fontSize: 16),
                    ),
              trailing: IconButton(
                icon: Icon(_isEditingAbout ? Icons.check : Icons.edit, color: AppColors.primary),
                onPressed: () {
                  if (_isEditingAbout) {
                    _saveProfile();
                  }
                  setState(() => _isEditingAbout = !_isEditingAbout);
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.phone, color: AppColors.textGrey),
              title: const Text(
                'Phone',
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
              subtitle: Text(
                '+1 123 456 7890',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
