import 'package:flutter/material.dart';

import '../theme/kkook_theme.dart';

class SocialDivider extends StatelessWidget {
  const SocialDivider({super.key, this.text = '또는 다음으로 로그인'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: KkookColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: KkookColors.hint),
          ),
        ),
        const Expanded(child: Divider(color: KkookColors.border)),
      ],
    );
  }
}
