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

        return StreamBuilder<AppRoute>(
          stream: FirestoreService.instance.watchAppRoute(user.uid),
          builder: (context, routeSnapshot) {
            if (routeSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            switch (routeSnapshot.data ?? AppRoute.onboarding) {
              case AppRoute.onboarding:
                return OnboardingScreen(user: user);
              case AppRoute.modeSelect:
                return const ModeSelectScreen();
              case AppRoute.coldTurkey:
                return ColdTurkeyDashboard(
                  key: ValueKey('cold-turkey-${user.uid}'),
                );
              case AppRoute.gradual:
                return GradualDashboard(
                  key: ValueKey('gradual-${user.uid}'),
                );
            }
          },
        );
      },
    );
  }
}
