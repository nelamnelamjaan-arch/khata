import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/core/config/app_constants.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';
import 'package:smart_khata_manager/features/auth/controllers/auth_controller.dart';

enum _AuthPanel { choose, email, phone, phoneOtp }

/// Unified sign-in screen — email, Google, and phone authentication.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthPanel _panel = _AuthPanel.choose;
  bool _isSignUp = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  AuthController get _controller => Get.find<AuthController>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showPanel(_AuthPanel panel) {
    _controller.clearError();
    if (panel != _AuthPanel.phone && panel != _AuthPanel.phoneOtp) {
      _controller.resetPhoneFlow();
    }
    setState(() => _panel = panel);
  }

  Future<void> _submitEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    if (_isSignUp) {
      await _controller.signUpWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      await _controller.loginWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }
  }

  Future<void> _sendPhoneCode() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    await _controller.sendPhoneCode(_phoneController.text);
    if (_controller.phoneSession.value != null && mounted) {
      setState(() => _panel = _AuthPanel.phoneOtp);
    }
  }

  Future<void> _confirmOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    await _controller.confirmPhoneOtp(_otpController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 28),
                  _buildErrorBanner(),
                  switch (_panel) {
                    _AuthPanel.choose => _buildChoosePanel(),
                    _AuthPanel.email => _buildEmailPanel(),
                    _AuthPanel.phone => _buildPhonePanel(),
                    _AuthPanel.phoneOtp => _buildOtpPanel(),
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.account_balance_wallet,
          size: 64,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        Text(
          AppConstants.appName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _panel == _AuthPanel.choose
              ? 'Sign in to access your private khata'
              : 'Your data is stored securely under your account',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Obx(() {
      final error = _controller.errorMessage.value;
      if (error == null || error.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Material(
          color: AppColors.payableLight,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.payable, fontSize: 13),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildChoosePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthMethodButton(
          icon: Icons.email_outlined,
          label: 'Login with Email',
          onPressed: () => _showPanel(_AuthPanel.email),
        ),
        const SizedBox(height: 12),
        _AuthMethodButton(
          icon: Icons.account_circle_outlined,
          label: 'Login with Google',
          onPressed: () => _controller.loginWithGoogle(),
          isLoading: _controller.isLoading,
        ),
        const SizedBox(height: 12),
        _AuthMethodButton(
          icon: Icons.phone_android_outlined,
          label: 'Login with Phone',
          onPressed: () => _showPanel(_AuthPanel.phone),
        ),
      ],
    );
  }

  Widget _buildEmailPanel() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => _showPanel(_AuthPanel.choose),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
            ),
          ),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.surface,
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Email is required';
              if (!email.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitEmail(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.surface,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (_isSignUp && value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          if (_isSignUp) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.surface,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 24),
          Obx(
            () => FilledButton(
              onPressed: _controller.isLoading.value ? null : _submitEmail,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isSignUp ? 'Create Account' : 'Sign In'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _isSignUp = !_isSignUp),
            child: Text(
              _isSignUp
                  ? 'Already have an account? Sign In'
                  : "Don't have an account? Sign Up",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhonePanel() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => _showPanel(_AuthPanel.choose),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
            ),
          ),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendPhoneCode(),
            decoration: const InputDecoration(
              labelText: 'Phone number',
              hintText: '+923001234567',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.surface,
            ),
            validator: (value) {
              final phone = value?.trim() ?? '';
              if (phone.isEmpty) return 'Phone number is required';
              if (phone.replaceAll(RegExp(r'[\d+]'), '').isNotEmpty) {
                return 'Use digits and + only';
              }
              if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
                return 'Enter a valid phone number with country code';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Include country code (e.g. +92 for Pakistan). '
            'On web, a reCAPTCHA popup may appear when you tap Send Code.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Obx(
            () => FilledButton(
              onPressed: _controller.isLoading.value ? null : _sendPhoneCode,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Send Verification Code'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpPanel() {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {
                _controller.resetPhoneFlow();
                _otpController.clear();
                setState(() => _panel = _AuthPanel.phone);
              },
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
            ),
          ),
          Obx(() {
            final phone = _controller.phoneSession.value?.phoneNumber ?? '';
            return Text(
              phone.isNotEmpty
                  ? 'Enter the code sent to $phone'
                  : 'Enter the verification code',
              style: const TextStyle(color: AppColors.textSecondary),
            );
          }),
          const SizedBox(height: 16),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _confirmOtp(),
            decoration: const InputDecoration(
              labelText: 'Verification code',
              prefixIcon: Icon(Icons.sms_outlined),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.surface,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Verification code is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Obx(
            () => FilledButton(
              onPressed: _controller.isLoading.value ? null : _confirmOtp,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Verify & Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthMethodButton extends StatelessWidget {
  const _AuthMethodButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isLoading,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final RxBool? isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading != null) {
      return Obx(
        () => OutlinedButton.icon(
          onPressed: isLoading!.value ? null : onPressed,
          icon: isLoading!.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: AppColors.surface,
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: AppColors.surface,
      ),
    );
  }
}
