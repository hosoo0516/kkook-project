import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/kkook_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName ?? '사용자';
    final email = user.email ?? '';

    return Scaffold(
      backgroundColor: KkookColors.background,
      appBar: AppBar(
        backgroundColor: KkookColors.background,
        elevation: 0,
        title: Text(
          'KKOOK',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => AuthService.instance.signOut(),
            child: const Text('로그아웃'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: KkookColors.primary.withValues(alpha: 0.12),
                backgroundImage:
                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person, size: 48, color: KkookColors.primary)
                    : null,
              ),
              const SizedBox(height: 24),
              Text(
                '$displayName님, 환영합니다!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                    ),
                textAlign: TextAlign.center,
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(email, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
