import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/tretech_logo.dart';
import '../providers/auth_provider.dart';

class SessionExpiredScreen extends ConsumerWidget {
  const SessionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.space3xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: TretechLogo(
                        frameSize: 92,
                        logoSize: 60,
                        radius: 24,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space3xl),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.spaceXxl),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.warningContainer,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd,
                              ),
                            ),
                            child: Icon(
                              Icons.lock_clock_rounded,
                              color: AppColors.warning,
                            ),

                          ),
                          const SizedBox(height: AppDimensions.spaceLg),
                          Text(
                            'Session expired',
                            style: AppTextStyles.headlineMedium,
                          ),
                          const SizedBox(height: AppDimensions.spaceSm),
                          Text(
                            'Your login session is no longer valid. Sign in again to continue using TRETECH.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceXxl),
                          AppButton(
                            label: 'Sign In Again',
                            onPressed: () async {
                              await ref
                                  .read(authProvider.notifier)
                                  .acknowledgeSessionExpired();
                              if (context.mounted) {
                                context.go(RouteNames.login);
                              }
                            },
                            icon: Icons.login_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
