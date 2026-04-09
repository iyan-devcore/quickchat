import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.inputBackgroundDark : AppColors.inputBackgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textGrey),
          icon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.textGrey) : null,
        ),
      ),
    );
  }
}
