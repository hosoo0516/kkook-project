import 'package:flutter/material.dart';

import '../theme/kkook_theme.dart';

class KkookAuthCard extends StatelessWidget {
  const KkookAuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: KkookColors.cardShadow,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
