import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/kkook_theme.dart';
import '../widgets/kkook_auth_card.dart';

class ModeSelectScreen extends StatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  bool _isSaving = false;

  Future<void> _selectMode(String mode) async {
    if (_isSaving) return;

    final user = AuthService.instance.currentUser;
    if (user == null) {
      _showMessage('로그인 정보가 없습니다.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 파이어베이스 Firestore에 모드 저장
      // 저장 성공 시 AuthGate의 StreamBuilder가 이를 감지하여 자동으로 대시보드로 전환합니다.
      await FirestoreService.instance.updateUserMode(user.uid, mode);
    } catch (_) {
      if (mounted) {
        _showMessage('모드 저장에 실패했습니다.');
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: KkookColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'KKOOK',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                '어떤 방식으로 시작할까요?',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '나중에 설정에서 변경할 수 있어요.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (_isSaving) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator(color: KkookColors.primary)),
              ],
              const SizedBox(height: 28),
              Expanded(
                child: _ModeCard(
                  title: '바로 금연 모드',
                  description:
                      '초 단위 타이머, 절약 금액, WHO 타임라인 기능이 제공됩니다.',
                  enabled: !_isSaving,
                  onTap: () => _selectMode(UserMode.coldTurkey),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _ModeCard(
                  title: '서서히 줄이기 모드',
                  description:
                      '자동 목표 조절, 롱프레스 차감 버튼, 하트 시스템 기능이 제공됩니다.',
                  enabled: !_isSaving,
                  onTap: () => _selectMode(UserMode.gradual),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.description,
    required this.onTap,
    this.enabled = true,
  });

  final String title;
  final String description;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: KkookAuthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: KkookColors.primary,
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: KkookColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}