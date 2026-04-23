import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_colors.dart';


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
      SnackBar(
        content: Text('Profile updated', style: GoogleFonts.nunito()),
        backgroundColor: AppColors.snapBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('User not found')));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.snapBlack,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Profile',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.snapBlack),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Yellow header with avatar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundImage: NetworkImage(user.avatarUrl),
                        backgroundColor: AppColors.surfaceVariant,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.snapBlack,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                            onPressed: () {},
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: GoogleFonts.nunito(
                      fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.snapBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.about,
                    style: GoogleFonts.nunito(
                      fontSize: 13, color: AppColors.snapBlack.withOpacity(0.65), fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Profile fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NAME', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textGrey, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _isEditingName
                              ? TextField(
                                  controller: _nameController,
                                  autofocus: true,
                                  style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.snapBlack),
                                  decoration: const InputDecoration(border: InputBorder.none),
                                  onSubmitted: (_) { setState(() => _isEditingName = false); _saveProfile(); },
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Text(user.name, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.snapBlack)),
                                ),
                        ),
                        IconButton(
                          icon: Icon(_isEditingName ? Icons.check_rounded : Icons.edit_rounded, color: AppColors.snapBlack, size: 20),
                          onPressed: () {
                            if (_isEditingName) _saveProfile();
                            setState(() => _isEditingName = !_isEditingName);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text('ABOUT', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textGrey, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _isEditingAbout
                              ? TextField(
                                  controller: _aboutController,
                                  autofocus: true,
                                  style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.snapBlack),
                                  decoration: const InputDecoration(border: InputBorder.none),
                                  onSubmitted: (_) { setState(() => _isEditingAbout = false); _saveProfile(); },
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Text(user.about, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.snapBlack)),
                                ),
                        ),
                        IconButton(
                          icon: Icon(_isEditingAbout ? Icons.check_rounded : Icons.edit_rounded, color: AppColors.snapBlack, size: 20),
                          onPressed: () {
                            if (_isEditingAbout) _saveProfile();
                            setState(() => _isEditingAbout = !_isEditingAbout);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text('PHONE', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textGrey, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Text('+1 123 456 7890', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.snapBlack)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
