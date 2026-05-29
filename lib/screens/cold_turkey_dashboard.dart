import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/cold_turkey_metrics.dart';
import '../services/firestore_service.dart';
import '../theme/kkook_theme.dart';
import '../widgets/kkook_auth_card.dart';
import 'onboarding_screen.dart';

class ColdTurkeyDashboard extends StatefulWidget {
  const ColdTurkeyDashboard({super.key});

  @override
  State<ColdTurkeyDashboard> createState() => _ColdTurkeyDashboardState();
}

class _ColdTurkeyDashboardState extends State<ColdTurkeyDashboard> {
  UserConfig? _config;
  String? _loadError;
  bool _isLoading = true;
  bool _isResetting = false;
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final user = AuthService.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _loadError = '로그인 정보가 없습니다.';
      });
      return;
    }

    try {
      final config = await FirestoreService.instance.getUserConfig(user.uid);
      if (!mounted) {
        return;
      }
      if (config == null) {
        setState(() {
          _config = null;
          _isLoading = false;
          _loadError = '온보딩 정보를 찾을 수 없습니다.';
        });
        return;
      }

      setState(() {
        _config = config;
        _isLoading = false;
        _loadError = null;
        _now = DateTime.now();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = '데이터를 불러오지 못했습니다.';
      });
    }
  }

  Future<void> _confirmRestart() async {
    final shouldRestart = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('금연 재시작'),
          content: const Text(
            '괜찮습니다. 실패는 더 나은 성공의 과정일 뿐입니다. 다시 마음을 다잡고 시작해 볼까요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('[ 다시 시작하기 ]'),
            ),
          ],
        );
      },
    );

    if (shouldRestart != true || _config == null) {
      return;
    }

    setState(() => _isResetting = true);

    final now = DateTime.now();
    try {
      await FirestoreService.instance.updateQuitStartDate(
        uid: _config!.uid,
        quitStartDate: now,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _config = _config!.copyWith(quitStartDate: now);
        _now = now;
        _isResetting = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isResetting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('재시작 처리에 실패했습니다.')),
      );
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
  }

  Future<void> _changeMode() async {
    final uid = _config?.uid;
    if (uid == null) {
      return;
    }

    try {
      await FirestoreService.instance.updateUserMode(uid, null);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모드 변경 처리에 실패했습니다.')),
      );
    }
  }

  Future<void> _editOnboarding() async {
    final user = AuthService.instance.currentUser;
    final config = _config;
    if (user == null || config == null) {
      return;
    }

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OnboardingScreen(
          user: user,
          isEditMode: true,
          initialConfig: config,
        ),
      ),
    );

    if (updated == true) {
      await _loadConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KkookColors.background,
      appBar: AppBar(
        title: const Text('바로 금연'),
        centerTitle: true,
        backgroundColor: KkookColors.background,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings_outlined),
            onSelected: (value) {
              switch (value) {
                case 'logout':
                  _logout();
                case 'change_mode':
                  _changeMode();
                case 'edit_onboarding':
                  _editOnboarding();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'logout', child: Text('로그아웃')),
              PopupMenuItem(value: 'change_mode', child: Text('금연 모드 변경')),
              PopupMenuItem(
                value: 'edit_onboarding',
                child: Text('흡연 정보 수정'),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _config == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isResetting ? null : _confirmRestart,
                    child: _isResetting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('[ 금연 재시작하기 ]'),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadConfig,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    final config = _config!;
    final elapsed = ColdTurkeyMetrics.elapsedSeconds(config.quitStartDate, _now);
    final breakdown = ColdTurkeyMetrics.breakdown(elapsed);
    final saved = ColdTurkeyMetrics.savedMoney(
      elapsedSeconds: elapsed,
      dailyCount: config.dailyCount,
      packPrice: config.packPrice,
      packQuantity: config.packQuantity,
    );
    final milestones = ColdTurkeyMetrics.milestoneStatuses(elapsed);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        _TimerCard(formatted: breakdown.formatted),
        const SizedBox(height: 12),
        _SavingsCard(amount: saved.floor()),
        const SizedBox(height: 12),
        _TimelineCard(milestones: milestones),
      ],
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({required this.formatted});

  final String formatted;

  @override
  Widget build(BuildContext context) {
    return KkookAuthCard(
      child: Column(
        children: [
          Text(
            '금연 진행 시간',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 16),
          Text(
            formatted,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: KkookColors.primary,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return KkookAuthCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: KkookColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: KkookColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '절약한 금액',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatAmount(amount)}원',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.milestones});

  final List<HealthMilestoneStatus> milestones;

  @override
  Widget build(BuildContext context) {
    return KkookAuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '건강 회복 타임라인',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          ...milestones.map(
            (status) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _MilestoneTile(status: status),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({required this.status});

  final HealthMilestoneStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: status.isCompleted,
          onChanged: null,
          activeColor: KkookColors.primary,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status.milestone.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status.milestone.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                    ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: status.progressPercent / 100,
                  minHeight: 6,
                  backgroundColor: KkookColors.border,
                  color: KkookColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '달성률 ${status.progressPercent.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: KkookColors.hint,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
