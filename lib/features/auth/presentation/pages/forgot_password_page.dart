import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final success = await ref.read(authNotifierProvider.notifier).sendPasswordReset(_emailCtrl.text);
    setState(() {
      _isLoading = false;
      _sent = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: _sent ? _buildSuccessState(context) : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Forgot your password?', style: AppTextStyles.headlineMedium(context)).animate().fadeIn(),
          const SizedBox(height: 8),
          Text(
            'Enter your email and we\'ll send you a reset link.',
            style: AppTextStyles.bodyMedium(context),
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 36),
          AppTextField(
            controller: _emailCtrl,
            label: 'Email address',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 28),
          AppButton(
            label: 'Send Reset Link',
            isLoading: _isLoading,
            onPressed: _submit,
            leadingIcon: Icons.send_rounded,
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read_rounded, size: 72, color: Color(0xFF22C55E))
            .animate()
            .scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text('Check your inbox', style: AppTextStyles.headlineMedium(context), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'A password reset link has been sent to ${_emailCtrl.text}',
          style: AppTextStyles.bodyMedium(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        AppButton(
          label: 'Back to Sign In',
          onPressed: () => context.pop(),
          variant: AppButtonVariant.outlined,
        ),
      ],
    );
  }
}
