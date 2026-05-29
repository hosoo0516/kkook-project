import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/cold_turkey_dashboard.dart';
import '../screens/gradual_dashboard.dart';
import '../screens/login_screen.dart';
import '../screens/mode_select_screen.dart';
import '../screens/onboarding_screen.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return StreamBuilder<UserConfig?>(
          stream: FirestoreService.instance.watchUserConfig(user.uid),
          builder: (context, configSnapshot) {
            if (configSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final config = configSnapshot.data;

            // 1. 온보딩 데이터 없음
            if (config == null || !config.isOnboardingCompleted) {
              return OnboardingScreen(user: user);
            }

            final mode = config.currentMode;

            // 2. 온보딩 완료, 모드 미선택
            if (mode == null || mode.isEmpty) {
              return const ModeSelectScreen();
            }

            // 3. 바로 금연 모드
            if (mode == UserMode.coldTurkey) {
              return const ColdTurkeyDashboard();
            }

            // 4. 서서히 줄이기 모드
            if (mode == UserMode.gradual) {
              return const GradualDashboard();
            }

            return const ModeSelectScreen();
          },
        );
      },
    );
  }
}
