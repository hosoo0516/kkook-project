import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kkook_test_1/services/firestore_service.dart';

class GradualDashboard extends StatefulWidget {
  const GradualDashboard({super.key});

  @override
  State<GradualDashboard> createState() => _GradualDashboardState();
}

class _GradualDashboardState extends State<GradualDashboard> with SingleTickerProviderStateMixin {
  // 상태 관리 변수
  bool _isLoading = true;       // 초기 데이터 로딩 상태
  bool _isProcessing = false;   // 버튼 클릭 시 중복 요청 및 인터랙션 차단용 오버레이 상태
  
  int _currentTotalLimit = 0;   // 오늘 총 제한량
  int _remainingSmokes = 0;     // 남은 개비 수
  double _reductionRate = 0.0;  // 현재 감소율 (%)

  // 타이머 및 애니메이션 관련
  Timer? _countdownTimer;
  Duration _timeToNextLimit = Duration.zero;
  late AnimationController _pressAnimationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // 롱프레스 시 버튼이 스케일 다운(작아지는) 피드백 애니메이션 설정
    _pressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressAnimationController, curve: Curves.easeInOut),
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

  /// 1. 초기 데이터 동기화 및 가져오기 (비동기)
/// 1. 초기 데이터 동기화 및 가져오기 (비동기)
  Future<void> _fetchAndSyncData() async {
    print("🔍 [디버그] 1. 데이터 가져오기 시작");
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    if (uid == null) {
      print("🚨 [디버그] 에러: 로그인된 UID가 없습니다.");
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }
    
    print("🔍 [디버그] 2. UID 확인 완료: $uid");

    try {
      print("🔍 [디버그] 3. 파이어베이스에 데이터 요청 중...");
      
      // 🔥 5초 타임아웃 강제 설정: 5초 넘게 응답 없으면 강제로 에러 발생시키고 로딩 종료
      final data = await FirestoreService.instance
          .syncAndGetGradualData(uid)
          .timeout(const Duration(seconds: 5), onTimeout: () {
            throw Exception("파이어베이스 서버 응답 5초 초과 (통신 지연)");
          });
          
      print("🔍 [디버그] 4. 데이터 가져오기 성공: $data");

      if (!mounted) return;

      final config = await FirestoreService.instance.getUserConfig(uid);
      if (!mounted) return;

      double rate = 0.0;
      if (config != null && config.dailyCount > 0) {
        final daysPassed = DateTime.now().difference(config.quitStartDate).inDays;
        final weeksPassed = daysPassed ~/ 7;
        rate = (0.10 * weeksPassed) * 100;
        if (rate > 90) rate = 90; 
      }

      print("🔍 [디버그] 5. 화면 UI 업데이트 완료, 로딩 종료!");
      setState(() {
        _currentTotalLimit = data['currentTotalLimit'] ?? 0;
        _remainingSmokes = data['remainingSmokes'] ?? 0;
        _reductionRate = rate;
        _isLoading = false;
      });
      
    } catch (e) {
      print("🚨 [디버그] 에러 발생 (여기서 무한로딩 끊김): $e");
      if (!mounted) return;
      
      // 에러가 나도 무조건 로딩은 끄도록 강제
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터 통신 에러: $e')),
      );
    }
  }

  /// 2. 자정(리셋 시간)까지 남은 시간 실시간 타이머 계산
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day + 1);
      
      setState(() {
        _timeToNextLimit = midnight.difference(now);
      });
    });
  }

  /// Duration 포맷팅 함수 (HH:mm:ss)
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  /// 3. 🔥 핵심 기능: 롱프레스를 통한 1개 차감 로직 (중복 차단 및 롤백 완벽 구현)
  Future<void> _deductSmoke() async {
    // 이미 처리 중이거나 남은 횟수가 없을 때 차단
    if (_isProcessing) return;
    if (_remainingSmokes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ 금일 한도가 이미 모두 소진되었습니다!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // [A] 백업본 생성 (네트워크 에러 시 롤백용 원상복구 데이터)
    final int backupRemaining = _remainingSmokes;

    // [B] 백엔드 저장 시작과 동시에 UI 인터랙션 원천 차단 조치 및 선제적 차감(Optimistic UI)
    setState(() {
      _isProcessing = true; 
      _remainingSmokes--; // 유저에게 빠른 피드백을 제공하기 위해 먼저 감소
    });

    try {
      // 서버에 차감 요청
      final success = await FirestoreService.instance.deductSmokeCount(uid);
      
      // 비동기 작업 완료 후 렌더링 상태 검증
      if (!mounted) return;

      if (!success) {
        throw Exception("Firestore 트랜잭션 차감 실패");
      }

      // 차감 성공 안내
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚬 1개비 차감되었습니다. 오늘도 페이스를 잘 유지하고 있어요!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // [C] 롤백(Rollback) 처리: 실패할 경우 숫자를 이전 상태로 완벽히 복구
      if (!mounted) return;
      setState(() {
        _remainingSmokes = backupRemaining;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚨 저장에 실패하여 숫자가 복구되었습니다: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      // 모든 작업이 끝나면 UI 차단 해제 및 애니메이션 초기화
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _pressAnimationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 테마 컬러 매칭 (Minimal Apple-Style Blue Palette)
    final primaryColor = const Color(0xFF4A72FF);
    final backgroundColor = const Color(0xFFF5F7FB);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 메인 대시보드 UI 콘텐츠 화면
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'KKOOK',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 메인 제한량 컨트롤 카드
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: GestureDetector(
                      onLongPressStart: (_) => _pressAnimationController.forward(),
                      onLongPressEnd: (_) => _pressAnimationController.reverse(),
                      onLongPress: _deductSmoke, // 롱프레스 시 차감 작동
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '점진적 감소 모드',
                                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              '오늘 목표 제한량',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            
                            // 💡 Zero Limit State 대응 가이드 반영
                            if (_remainingSmokes == 0) ...[
                              const Text(
                                '금일 한도 소진',
                                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.redAccent),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '오늘의 목표를 달성했습니다! 내일 또 한 걸음 나아가요. 👍',
                                style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ] else ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '$_remainingSmokes',
                                    style: TextStyle(fontSize: 72, fontWeight: FontWeight.w800, color: primaryColor),
                                  ),
                                  Text(
                                    ' / $_currentTotalLimit',
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.black38),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 32),
                            Text(
                              _remainingSmokes == 0 ? '오늘 흡연은 여기서 끝!' : '길게 눌러서 1개 차감하기',
                              style: const TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 하단 통계 서브 카드 세션
                  Row(
                    children: [
                      // 타이머 카드
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.access_time_filled_rounded, color: primaryColor, size: 24),
                              const SizedBox(height: 14),
                              const Text('다음 제한까지', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 6),
                              Text(
                                _formatDuration(_timeToNextLimit),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 감소율 통계 카드
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.trending_down_rounded, color: Colors.teal, size: 24),
                              const SizedBox(height: 14),
                              const Text('초기 대비', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 6),
                              Text(
                                '-${_reductionRate.toStringAsFixed(0)}% 감소',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),

          // ⭐ [엄격 보장 조건] 중복 요청 및 인터랙션 차단용 불투명 로딩 오버레이 레이어
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.25), // 화면을 살짝 어둡게 해서 터치 입력 원천 봉쇄
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}