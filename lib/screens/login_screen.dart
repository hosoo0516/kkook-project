import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/kkook_theme.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/kkook_auth_card.dart';
import '../widgets/kkook_labeled_field.dart';
import '../widgets/social_divider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isLoading => _isEmailLoading || _isGoogleLoading;

  Future<void> _runAuth(Future<SignInResult> Function() action) async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _isEmailLoading = true);

    final result = await action();

    if (!mounted) return;
    setState(() => _isEmailLoading = false);

    if (result.isSuccess) return;
    _showError(result.errorMessage);
  }

  Future<void> _handleEmailLogin() async {
    await _runAuth(
      () => AuthService.instance.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _isGoogleLoading = true);

    final result = await AuthService.instance.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result.isSuccess) return;
    _showError(result.errorMessage);
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('비밀번호 재설정을 위해 이메일을 입력해 주세요.');
      return;
    }

    final result = await AuthService.instance.sendPasswordResetEmail(email);
    if (!mounted) return;
    if (result.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호 재설정 메일을 보냈습니다.')),
      );
      return;
    }
    _showError(result.errorMessage);
  }

  void _showError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? '요청을 처리하지 못했습니다.')),
    );
  }

  void _goToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KkookColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 28),
              Text(
                'KKOOK',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 28,
                      letterSpacing: 1.5,
                    ),
              ),
              const SizedBox(height: 28),
              Text(
                '환영합니다',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '금연 여정을 시작하려면 로그인하세요',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              KkookAuthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KkookLabeledField(
                      label: '이메일 주소',
                      controller: _emailController,
                      hint: 'example@email.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 18),
                    KkookLabeledField(
                      label: '비밀번호',
                      controller: _passwordController,
                      hint: '••••••••',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleEmailLogin(),
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleForgotPassword,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: KkookColors.label,
                        ),
                        child: const Text(
                          '비밀번호를 잊으셨나요?',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleEmailLogin,
                      child: _isEmailLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('로그인'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SocialDivider(),
              const SizedBox(height: 20),
              GoogleSignInButton(
                isLoading: _isGoogleLoading,
                onPressed: _handleGoogleSignIn,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '계정이 없으신가요? ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : _goToSignUp,
                    child: const Text(
                      '회원가입',
                      style: TextStyle(
                        color: KkookColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                '© ${DateTime.now().year} KKOOK. All rights reserved.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: KkookColors.hint,
                    ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
