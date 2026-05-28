import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/kkook_theme.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/kkook_labeled_field.dart';
import '../widgets/social_divider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isLoading => _isSubmitting || _isGoogleLoading;

  Future<void> _handleSignUp() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final result = await AuthService.instance.signUpWithEmail(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      Navigator.of(context).pop();
      return;
    }
    _showError(result.errorMessage);
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _isGoogleLoading = true);

    final result = await AuthService.instance.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result.isSuccess) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    _showError(result.errorMessage);
  }

  void _showError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? '요청을 처리하지 못했습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KkookColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                color: const Color(0xFF374151),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '반갑습니다!\nKKOOK과 함께 시작해요',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: KkookColors.primary,
                            fontSize: 24,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '건강한 습관을 위한 첫걸음을 내딛어 보세요.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    KkookLabeledField(
                      label: '이름',
                      controller: _nameController,
                      hint: '홍길동',
                      textInputAction: TextInputAction.next,
                      suffixIcon: const Icon(
                        Icons.person_outline,
                        color: KkookColors.hint,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 20),
                    KkookLabeledField(
                      label: '이메일 주소',
                      controller: _emailController,
                      hint: 'example@email.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      suffixIcon: const Icon(
                        Icons.mail_outline,
                        color: KkookColors.hint,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 20),
                    KkookLabeledField(
                      label: '비밀번호',
                      controller: _passwordController,
                      hint: '••••••••',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleSignUp(),
                      helperText: '보안을 위해 강력한 비밀번호를 권장합니다',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: KkookColors.hint,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '가입 시 KKOOK의 이용약관 및 개인정보 처리방침에 동의하는 것으로 간주됩니다.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            height: 1.6,
                          ),
                    ),
                    const SizedBox(height: 28),
                    const SocialDivider(text: '또는 Google로 가입'),
                    const SizedBox(height: 20),
                    GoogleSignInButton(
                      isLoading: _isGoogleLoading,
                      onPressed: _handleGoogleSignIn,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignUp,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('시작하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
