import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/chat_prefs_provider.dart';
import '../../utils/app_colors.dart';

/// Full-screen screen for chat customisation:
/// • Wallpaper  — default (dark), gradient presets, or custom image from gallery
/// • Bubble colour — palette of 8 accent colours for outgoing messages
class ChatCustomizationScreen extends StatefulWidget {
  const ChatCustomizationScreen({super.key});

  @override
  State<ChatCustomizationScreen> createState() => _ChatCustomizationScreenState();
}

class _ChatCustomizationScreenState extends State<ChatCustomizationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Pick image from gallery ───────────────────────────────
  Future<void> _pickWallpaperImage(ChatPrefsProvider prefs) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path != null) {
          await prefs.setImageWallpaper(path);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              _snackBar('Wallpaper updated!'),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Wallpaper pick error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Chat Customization',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textLight,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textGrey,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Wallpaper'),
            Tab(text: 'Bubble Color'),
          ],
        ),
      ),
      body: Consumer<ChatPrefsProvider>(
        builder: (context, prefs, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _WallpaperTab(prefs: prefs, onPickImage: () => _pickWallpaperImage(prefs)),
              _BubbleColorTab(prefs: prefs),
            ],
          );
        },
      ),
    );
  }

  SnackBar _snackBar(String text) => SnackBar(
    content: Text(text, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
    backgroundColor: AppColors.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

// ────────────────────────────────────────────────────────────
// Wallpaper Tab
// ────────────────────────────────────────────────────────────
class _WallpaperTab extends StatelessWidget {
  final ChatPrefsProvider prefs;
  final VoidCallback onPickImage;

  const _WallpaperTab({required this.prefs, required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Live preview ─────────────────────────────────
          _SectionLabel('Preview'),
          const SizedBox(height: 12),
          _WallpaperPreview(prefs: prefs),
          const SizedBox(height: 28),

          // ── Default ──────────────────────────────────────
          _SectionLabel('Default'),
          const SizedBox(height: 12),
          _OptionTile(
            selected: prefs.wallpaperType == WallpaperType.none,
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.dark_mode_rounded, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 16),
                Text('Dark (Default)',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textLight)),
              ],
            ),
            onTap: () => prefs.clearWallpaper(),
          ),

          const SizedBox(height: 28),

          // ── Gradient presets ─────────────────────────────
          _SectionLabel('Gradient Presets'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ChatPrefsProvider.gradients.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, i) {
              final isSelected = prefs.wallpaperType == WallpaperType.gradient &&
                  prefs.wallpaperGradientIndex == i;
              return GestureDetector(
                onTap: () => prefs.setGradientWallpaper(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: ChatPrefsProvider.gradients[i],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 10)]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28)
                      : null,
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // ── Custom image ─────────────────────────────────
          _SectionLabel('Custom Image'),
          const SizedBox(height: 12),
          _OptionTile(
            selected: prefs.wallpaperType == WallpaperType.image,
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choose from Gallery',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppColors.textLight)),
                      if (prefs.wallpaperType == WallpaperType.image &&
                          prefs.wallpaperImagePath != null)
                        Text(
                          prefs.wallpaperImagePath!.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: AppColors.textGrey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            onTap: onPickImage,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Bubble Color Tab
// ────────────────────────────────────────────────────────────
class _BubbleColorTab extends StatelessWidget {
  final ChatPrefsProvider prefs;

  const _BubbleColorTab({required this.prefs});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Your message bubble colour'),
          const SizedBox(height: 16),

          // ── Live preview ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Their message
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                    ),
                    child: Text('Hey, how are you? 👋',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 10),
                // My message
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: prefs.myBubbleColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: prefs.myBubbleColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text("I'm great, thanks! 😊",
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          _SectionLabel('Choose a colour'),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ChatPrefsProvider.bubbleColors.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, i) {
              final color = ChatPrefsProvider.bubbleColors[i];
              final isSelected = prefs.myBubbleColorIndex == i;
              return GestureDetector(
                onTap: () => prefs.setBubbleColor(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(isSelected ? 0.5 : 0.2),
                        blurRadius: isSelected ? 12 : 4,
                        spreadRadius: isSelected ? 2 : 0,
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 26)
                      : null,
                ),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────

class _WallpaperPreview extends StatelessWidget {
  final ChatPrefsProvider prefs;
  const _WallpaperPreview({required this.prefs});

  @override
  Widget build(BuildContext context) {
    Widget bg;
    switch (prefs.wallpaperType) {
      case WallpaperType.gradient:
        bg = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: ChatPrefsProvider.gradients[prefs.wallpaperGradientIndex],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
        break;
      case WallpaperType.image:
        if (prefs.wallpaperImagePath != null) {
          bg = Image.file(
            File(prefs.wallpaperImagePath!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: AppColors.backgroundDark),
          );
        } else {
          bg = Container(color: AppColors.backgroundDark);
        }
        break;
      default:
        bg = Container(color: AppColors.backgroundDark);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            bg,
            // Sample message bubbles overlay
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: Text('Hello there 👋',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white, fontSize: 13)),
              ),
            ),
            Positioned(
              bottom: 56,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: prefs.myBubbleColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: Text('Looking great! ✨',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textGrey,
          letterSpacing: 1.1,
        ),
      );
}

class _OptionTile extends StatelessWidget {
  final bool selected;
  final Widget child;
  final VoidCallback onTap;

  const _OptionTile({
    required this.selected,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 8,
                )]
              : [],
        ),
        child: Row(
          children: [
            Expanded(child: child),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
