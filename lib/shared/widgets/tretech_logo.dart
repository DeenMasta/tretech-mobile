import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TretechLogo extends StatelessWidget {
  const TretechLogo({
    super.key,
    this.frameSize = 80,
    this.logoSize = 52,
    this.radius = 20,
    this.showFrame = true,
  });

  final double frameSize;
  final double logoSize;
  final double radius;
  final bool showFrame;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/logo/tretech_logo.png',
      width: logoSize,
      height: logoSize,
      fit: BoxFit.contain,
    );

    if (!showFrame) {
      return logo;
    }

    return Container(
      width: frameSize,
      height: frameSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.sidebarBg],
        ),

        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(child: logo),
    );
  }
}
