import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/cold_turkey_metrics.dart';
import '../services/firestore_service.dart';
import '../theme/kkook_theme.dart';
import '../widgets/kkook_auth_card.dart';
import '../screens/friend_room.dart'; // 🛠️ 이동할 화면의 정의를 위해 임포트 추가
import 'onboarding_screen.dart';

import 'package:kkook_test_1/services/firebase_service.dart';
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

  // 🛠️ 성범님 말씀대로 하단 onPressed 작동을 위해 먼저 완벽하게 선언(정의)해 둔 함수들입니다!
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('재시작 처리에 실패했습니다.')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모드 변경 처리에 실패했습니다.')));
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
              PopupMenuItem(value: 'edit_onboarding', child: Text('흡연 정보 수정')),
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
                    onPressed: _isResetting
                        ? null
                        : _confirmRestart, // 👈 위에서 먼저 정의해 뒀기 때문에 이제 에러가 나지 않습니다!
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
    final elapsed = ColdTurkeyMetrics.elapsedSeconds(
      config.quitStartDate,
      _now,
    );
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

        // ⭕ 상수(const) 충돌과 구조를 완벽하게 교정하여 이제 onPressed에 빨간 줄이 절대 생기지 않습니다.
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: KkookColors.cardShadow,
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                      final firebaseService = FirebaseService();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('금연방 정보 확인 중...'), duration: Duration(milliseconds: 500)),
                      );

                      // 🔍 이미 가입되거나 참여 중인 방이 있는지 확인
                      String? joinedTeamId = await firebaseService.checkUserJoinedTeam();

                      if (!context.mounted) return;

                      // 🚪 1. 이미 들어간 방이 있다면 팝업창 없이 바로 화면 이동!
                      if (joinedTeamId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FriendRoomPage()),
                        );
                        return;
                      }

                      // 🤝 2. 가입된 방이 없을 때만 초대 코드 입력 및 방 만들기 팝업창 오픈
                      showDialog(
                        context: context,
                        builder: (context) {
                          final TextEditingController codeController = TextEditingController();
                          String? generatedCode;

                          return StatefulBuilder(
                            builder: (context, setPopupState) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text(
                                  '🤝 실시간 친구 금연방',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 방이 새로 개설되었을 때 코드를 상단에 노출
                                    if (generatedCode != null) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: KkookColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: KkookColors.primary.withOpacity(0.3)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '📢 방이 생성되었습니다! 친구에게 공유하세요:',
                                              style: TextStyle(fontSize: 11, color: KkookColors.primary, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 6),
                                            SelectableText(
                                              generatedCode!,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.black87,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      const Text(
                                        '새로운 금연방을 개설하여 초대 코드를 생성하거나, 친구에게 받은 초대 코드를 입력해 보세요.',
                                        style: TextStyle(fontSize: 13, color: Colors.black54),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    // ⌨️ [정상 복구] 초대 코드를 직접 타이핑해 참여할 수 있는 텍스트 필드
                                    TextField(
                                      controller: codeController,
                                      decoration: InputDecoration(
                                        hintText: '초대 코드(방 ID) 입력',
                                        hintStyle: const TextStyle(fontSize: 13),
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                actionsAlignment: MainAxisAlignment.spaceBetween,
                                actions: [
                                  // 1️⃣ 방 만들기 버튼
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        String newTeamId = await firebaseService.createTeam('우리 함께 금연방');
                                        setPopupState(() {
                                          generatedCode = newTeamId;
                                        });
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('방 생성 실패: $e')),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text('방 만들기', style: TextStyle(color: KkookColors.primary, fontWeight: FontWeight.bold)),
                                  ),
                                  
                                  // 2️⃣ [정상 복구] 입력한 초대 코드로 다른 사람 방에 참여하는 버튼
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: KkookColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () async {
                                      // 텍스트 창에 입력된 코드를 최우선으로 가져옵니다.
                                      final enteredCode = codeController.text.trim();

                                      // 만약 텍스트 창이 비어있고 방금 내가 방을 만든 상태라면 생성된 코드를 사용합니다.
                                      final finalCode = enteredCode.isEmpty ? (generatedCode ?? '') : enteredCode;

                                      if (finalCode.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('초대 코드를 입력하거나 방을 먼저 생성해 주세요.')),
                                        );
                                        return;
                                      }

                                      try {
                                        // 파이어베이스에 입력한 초대코드로 가입 처리 진행
                                        await firebaseService.joinTeam(finalCode);
                                        if (context.mounted) {
                                          Navigator.pop(context); // 팝업 닫기
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const FriendRoomPage()),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('입장 실패: $e')),
                                          );
                                        }
                                      }
                                    },
                                    child: Text(
                                      codeController.text.trim().isEmpty && generatedCode != null ? '바로 입장하기' : '참여하기', 
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: KkookColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: KkookColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '실시간 친구 금연방',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '친구들과 실시간 타이머와 랭킹을 공유해요',
                              style: TextStyle(
                                fontSize: 12,
                                color: KkookColors.hint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: KkookColors.hint,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
        _TimelineCard(milestones: milestones),
      ],
    );
  }
} // 👈 _ColdTurkeyDashboardState 클래스를 정상적으로 닫아주는 중괄호 // 👈 _ColdTurkeyDashboardState 클래스의 끝을 닫아주는 중괄호

class _TimerCard extends StatelessWidget {
  const _TimerCard({required this.formatted});

  final String formatted;

  @override
  Widget build(BuildContext context) {
    return KkookAuthCard(
      child: Column(
        children: [
          Text('금연 진행 시간', style: Theme.of(context).textTheme.labelMedium),
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
              color: KkookColors.primary.withOpacity(0.1),
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
                Text('절약한 금액', style: Theme.of(context).textTheme.labelMedium),
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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 18),
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 13),
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
