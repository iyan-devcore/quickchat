import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../providers/user_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController  = TextEditingController();
  final _aboutController = TextEditingController();
  bool _isEditingName  = false;
  bool _isEditingAbout = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user != null) {
      _nameController.text  = user.name;
      _aboutController.text = user.about;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile({String? avatarUrl}) async {
    await Provider.of<UserProvider>(context, listen: false).updateProfile(
      _nameController.text,
      _aboutController.text,
      avatarUrl: avatarUrl,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Pick an image with FilePicker, upload to the server, then save the URL.
  Future<void> _pickAndUploadPhoto() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) return;

      setState(() => _isUploadingPhoto = true);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/api/upload'),
      );
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body);
        final url = json['url']?.toString();
        if (url != null && mounted) {
          await _saveProfile(avatarUrl: url);
        }
      } else {
        if (mounted) _showError('Upload failed. Please try again.');
      }
    } catch (e) {
      if (mounted) _showError('Could not pick photo: $e');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: Colors.redAccent,
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
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textLight,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Profile',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textLight),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header with avatar ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      // Avatar ring
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.backgroundDark,
                          shape: BoxShape.circle,
                        ),
                        child: _isUploadingPhoto
                            ? const SizedBox(
                                width: 112,
                                height: 112,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : CircleAvatar(
                                radius: 56,
                                backgroundImage: user.avatarUrl.isNotEmpty
                                    ? NetworkImage(user.avatarUrl)
                                    : null,
                                backgroundColor: AppColors.surfaceVariant,
                                child: user.avatarUrl.isEmpty
                                    ? Text(
                                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                      ),
                      // Camera button
                      Positioned(
                        bottom: 4, right: 4,
                        child: GestureDetector(
                          onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.about,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Editable fields ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('NAME'),
                  const SizedBox(height: 8),
                  _editableField(
                    controller: _nameController,
                    displayText: user.name,
                    isEditing: _isEditingName,
                    onEdit: () => setState(() => _isEditingName = true),
                    onSave: () {
                      setState(() => _isEditingName = false);
                      _saveProfile();
                    },
                  ),

                  const SizedBox(height: 24),
                  _fieldLabel('ABOUT'),
                  const SizedBox(height: 8),
                  _editableField(
                    controller: _aboutController,
                    displayText: user.about,
                    isEditing: _isEditingAbout,
                    onEdit: () => setState(() => _isEditingAbout = true),
                    onSave: () {
                      setState(() => _isEditingAbout = false);
                      _saveProfile();
                    },
                  ),

                  const SizedBox(height: 24),
                  _fieldLabel('EMAIL'),
                  const SizedBox(height: 8),
                  _readonlyField(user.email, Icons.email_outlined),

                  const SizedBox(height: 24),

                  // ── Change photo button ───────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                      icon: _isUploadingPhoto
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_rounded, size: 20),
                      label: Text(
                        _isUploadingPhoto ? 'Uploading...' : 'Change Profile Photo',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 12, fontWeight: FontWeight.w800,
      color: AppColors.textGrey, letterSpacing: 1.0,
    ),
  );

  Widget _editableField({
    required TextEditingController controller,
    required String displayText,
    required bool isEditing,
    required VoidCallback onEdit,
    required VoidCallback onSave,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEditing ? AppColors.primary : AppColors.border,
          width: isEditing ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: isEditing
                ? TextField(
                    controller: controller,
                    autofocus: true,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textLight,
                    ),
                    decoration: const InputDecoration(border: InputBorder.none),
                    onSubmitted: (_) => onSave(),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(displayText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textLight,
                        )),
                  ),
          ),
          IconButton(
            icon: Icon(
              isEditing ? Icons.check_rounded : Icons.edit_rounded,
              color: AppColors.primary, size: 22,
            ),
            onPressed: isEditing ? onSave : onEdit,
          ),
        ],
      ),
    );
  }

  Widget _readonlyField(String value, IconData icon) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textGrey, size: 18),
          const SizedBox(width: 12),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textLight,
              )),
        ],
      ),
    );
  }
}
