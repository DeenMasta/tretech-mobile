import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/tretech_logo.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passwordCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space3xl,
                vertical: AppDimensions.space3xl,
              ),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              const TretechLogo(
                                frameSize: 88,
                                logoSize: 58,
                                radius: 24,
                              ),
                              const SizedBox(height: AppDimensions.spaceLg),
                              Text(
                                'TRETECH',
                                style: AppTextStyles.titleLarge.copyWith(
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space4xl),
                        Text(
                          'Welcome back',
                          style: AppTextStyles.headlineMedium,
                        ),
                        const SizedBox(height: AppDimensions.spaceXs),
                        Text(
                          'Sign in to your account to continue',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space3xl),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              AppTextField(
                                controller: _emailCtrl,
                                focusNode: _emailFocus,
                                label: 'Email Address',
                                hint: 'you@tretech.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                onSubmitted: (_) =>
                                    _passwordFocus.requestFocus(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+',
                                  ).hasMatch(value)) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppDimensions.spaceXl),
                              AppTextField(
                                controller: _passwordCtrl,
                                focusNode: _passwordFocus,
                                label: 'Password',
                                hint: '........',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onSubmitted: (_) => _onLogin(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (value.length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppDimensions.spaceSm),
                              Row(
                                children: [
                                  Transform.translate(
                                    offset: const Offset(-10, 0),
                                    child: Checkbox(
                                      value: authState.rememberMe,
                                      onChanged: (value) {
                                        ref
                                            .read(authProvider.notifier)
                                            .setRememberMe(value ?? false);
                                      },
                                      activeColor: AppColors.primary,
                                      checkColor: AppColors.onPrimary,

                                      side: BorderSide(
                                        color: AppColors.border,
                                      ),

                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Remember me',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.push(RouteNames.forgotPassword),
                                    child: const Text('Forgot password?'),
                                  ),
                                ],
                              ),
                              if (authState.status == AuthStatus.error &&
                                  authState.error != null) ...[
                                const SizedBox(height: AppDimensions.spaceMd),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(
                                    AppDimensions.spaceMd,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorContainer,
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusMd,
                                    ),
                                    border: Border.all(
                                      color: AppColors.error.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 1),
                                        child: Icon(
                                          Icons.error_outline_rounded,
                                          size: 16,
                                          color: AppColors.error,
                                        ),
                                      ),

                                      const SizedBox(
                                        width: AppDimensions.spaceSm,
                                      ),
                                      Expanded(
                                        child: Text(
                                          authState.error!,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(color: AppColors.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppDimensions.space3xl),
                              AppButton(
                                label: 'Sign In',
                                onPressed: _onLogin,
                                isLoading: authState.isLoading,
                                icon: Icons.login_rounded,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceXxl),
                        Center(
                          child: Text(
                            'Tretech Warehouse Management v1.0.0\nFor support contact your system administrator',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textDisabled,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
