import 'package:flutter/material.dart';

import '../theme/kkook_theme.dart';

class GradualDashboard extends StatelessWidget {
  const GradualDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KkookColors.background,
      appBar: AppBar(
        title: const Text('서서히 줄이기 모드'),
        backgroundColor: KkookColors.background,
      ),
      body: const Center(
        child: Text('GradualDashboard (구현 예정)'),
      ),
    );
  }
}
