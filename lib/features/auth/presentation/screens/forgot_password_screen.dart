import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/tretech_logo.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textSecondary,
                      ),

                    ),
                    const SizedBox(height: AppDimensions.spaceLg),
                    const Center(
                      child: TretechLogo(
                        frameSize: 84,
                        logoSize: 56,
                        radius: 24,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space3xl),
                    Text(
                      'Forgot password?',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: AppDimensions.spaceSm),
                    Text(
                      'Password reset is not connected in the mobile app yet. Contact your system administrator to reset or reissue your account password.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXxl),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.spaceLg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.infoContainer,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMd,
                                  ),
                                ),
                                child: Icon(
                                  Icons.support_agent_rounded,
                                  color: AppColors.info,
                                ),

                              ),
                              const SizedBox(width: AppDimensions.spaceMd),
                              Text(
                                'Support Handoff',
                                style: AppTextStyles.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spaceMd),
                          Text(
                            'Provide your work email and ask the administrator to reset your password. Once they confirm, return here and sign in again.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXxl),
                    AppButton(
                      label: 'Back to Sign In',
                      onPressed: () => context.go(RouteNames.login),
                      icon: Icons.login_rounded,
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
