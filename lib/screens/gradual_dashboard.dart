import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/kkook_theme.dart';
import 'onboarding_screen.dart';

class GradualDashboard extends StatefulWidget {
  const GradualDashboard({super.key});

  @override
  State<GradualDashboard> createState() => _GradualDashboardState();
}

class _GradualDashboardState extends State<GradualDashboard>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isDeducting = false;
  String? _loadError;

  int _currentTotalLimit = 0;
  int _remainingSmokes = 0;
  double _reductionRate = 0;

  Timer? _countdownTimer;
  Duration _timeToNextLimit = Duration.zero;
  late AnimationController _pressAnimationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _pressAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _fetchAndSyncData();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pressAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndSyncData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _isLoading = false;
        _loadError = '로그인 정보가 없습니다.';
      });
      return;
    }

    try {
      final data = await FirestoreService.instance.syncAndGetGradualData(uid);
      if (!mounted) {
        return;
      }

      setState(() {
        _currentTotalLimit = data['currentTotalLimit'] as int? ?? 0;
        _remainingSmokes = data['remainingSmokes'] as int? ?? 0;
        _reductionRate = (data['reductionPercent'] as num?)?.toDouble() ?? 0;
        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = '데이터를 불러오지 못했습니다: $e';
      });
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day + 1);
      setState(() => _timeToNextLimit = midnight.difference(now));
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inHours)}:'
        '${twoDigits(duration.inMinutes.remainder(60))}:'
        '${twoDigits(duration.inSeconds.remainder(60))}';
  }

  Future<void> _deductSmoke() async {
    if (_isDeducting) {
      return;
    }
    if (_remainingSmokes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('금일 한도가 이미 모두 소진되었습니다.')),
      );
      return;
    }

    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final backupRemaining = _remainingSmokes;

    setState(() {
      _isDeducting = true;
      _remainingSmokes--;
    });

    String? error;
    try {
      error = await FirestoreService.instance.deductSmokeCount(
        uid,
        fromRemaining: backupRemaining,
      );
    } on TimeoutException {
      error = '저장 시간이 초과되었습니다.';
    } catch (e) {
      error = e.toString();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isDeducting = false;
      if (error != null && error != 'timeout') {
        _remainingSmokes = backupRemaining;
      }
    });
    _pressAnimationController.reverse();

    if (error == null) {
      return;
    }
    if (error == 'timeout') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '서버 응답이 느립니다. 숫자는 유지되며, 연결되면 자동 저장됩니다.',
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('저장에 실패하여 숫자가 복구되었습니다. ($error)')),
    );
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
  }

  Future<void> _changeMode() async {
    final uid = AuthService.instance.currentUser?.uid;
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
    if (user == null) {
      return;
    }

    final config = await FirestoreService.instance.getUserConfig(user.uid);
    if (config == null || !mounted) {
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
      await _fetchAndSyncData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KkookColors.background,
      appBar: AppBar(
        title: const Text('서서히 줄이기'),
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
                onPressed: _fetchAndSyncData,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: GestureDetector(
                onLongPressStart: (_) {
                  if (!_isDeducting) {
                    _pressAnimationController.forward();
                  }
                },
                onLongPressEnd: (_) => _pressAnimationController.reverse(),
                onLongPress: _isDeducting ? null : _deductSmoke,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: KkookColors.cardShadow,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: KkookColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '점진적 감소 모드',
                          style: TextStyle(
                            color: KkookColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '오늘 목표 제한량',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_remainingSmokes == 0) ...[
                        const Text(
                          '금일 한도 소진',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '오늘의 목표를 달성했습니다. 내일 또 한 걸음 나아가요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: KkookColors.label),
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$_remainingSmokes',
                              style: const TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.w800,
                                color: KkookColors.primary,
                              ),
                            ),
                            Text(
                              ' / $_currentTotalLimit',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 32),
                      Text(
                        _remainingSmokes == 0
                            ? '오늘 흡연은 여기서 끝!'
                            : '길게 눌러서 1개 차감하기',
                        style: const TextStyle(
                          color: KkookColors.hint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.access_time_filled_rounded,
                    label: '다음 제한까지',
                    value: _formatDuration(_timeToNextLimit),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    icon: Icons.trending_down_rounded,
                    label: '초기 대비',
                    value: '-${_reductionRate.toStringAsFixed(0)}% 감소',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: KkookColors.primary),
          const SizedBox(height: 14),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
