class ElapsedBreakdown {
  const ElapsedBreakdown({
    required this.totalSeconds,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  final int totalSeconds;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;

  String get formatted =>
      '${days.toString().padLeft(2, '0')}일 '
      '${hours.toString().padLeft(2, '0')}시간 '
      '${minutes.toString().padLeft(2, '0')}분 '
      '${seconds.toString().padLeft(2, '0')}초';
}

class HealthMilestone {
  const HealthMilestone({
    required this.title,
    required this.description,
    required this.targetSeconds,
  });

  final String title;
  final String description;
  final int targetSeconds;
}

class HealthMilestoneStatus {
  const HealthMilestoneStatus({
    required this.milestone,
    required this.progressPercent,
    required this.isCompleted,
  });

  final HealthMilestone milestone;
  final double progressPercent;
  final bool isCompleted;
}

class ColdTurkeyMetrics {
  static const int secondsPerDay = 86400;

  static const List<HealthMilestone> milestones = [
    HealthMilestone(
      title: '혈압 정상화',
      description: '상승했던 혈압과 맥박이 떨어지고 손발 온도가 정상으로 상승.',
      targetSeconds: 20 * 60,
    ),
    HealthMilestone(
      title: '산소 충전',
      description: '혈액 속 일산화탄소(CO) 수치가 정상으로 떨어지고 산소 농도 정상화.',
      targetSeconds: 12 * 60 * 60,
    ),
    HealthMilestone(
      title: '심장 보호',
      description: '일산화탄소 배출로 심장마비 발생 위험 감소 시작.',
      targetSeconds: secondsPerDay,
    ),
    HealthMilestone(
      title: '감각 깨어나기',
      description: '체내 니코틴 완벽 배출, 후각과 미각 회복.',
      targetSeconds: 2 * secondsPerDay,
    ),
    HealthMilestone(
      title: '숨쉬기 편안함',
      description:
          '기관지가 이완되어 호흡이 부드러워지고 폐활량 증가. (니코틴 금단 증상 피크 극복)',
      targetSeconds: 3 * secondsPerDay,
    ),
    HealthMilestone(
      title: '혈액 순환',
      description: '전신의 혈액 순환 개선 및 폐 기능 점진적 향상 시작.',
      targetSeconds: 14 * secondsPerDay,
    ),
    HealthMilestone(
      title: '장기 세포 복구',
      description: '혈관 내벽 기능이 정상화되고 위궤양 발생 위험 감소.',
      targetSeconds: 90 * secondsPerDay,
    ),
    HealthMilestone(
      title: '폐 청소',
      description: '기침/호흡 곤란 감소, 폐 내부 섬모 세포 재생으로 자체 정화 능력 정상화.',
      targetSeconds: 273 * secondsPerDay,
    ),
    HealthMilestone(
      title: '심장병 위험 절반',
      description: '관상동맥 질환(심장병) 위험이 흡연자의 50% 수준으로 감소.',
      targetSeconds: 365 * secondsPerDay,
    ),
    HealthMilestone(
      title: '혈관 정상화',
      description: '뇌졸중(중풍) 발병 위험이 비흡연자 수준으로 감소.',
      targetSeconds: 5 * 365 * secondsPerDay,
    ),
    HealthMilestone(
      title: '맥시멈 성취',
      description: '폐암 사망 확률이 흡연자의 절반으로 감소 및 각종 암 발생 위험 급격히 감소.',
      targetSeconds: 10 * 365 * secondsPerDay,
    ),
  ];

  static int elapsedSeconds(DateTime quitStartDate, DateTime now) {
    final diff = now.difference(quitStartDate).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  static ElapsedBreakdown breakdown(int totalSeconds) {
    final days = totalSeconds ~/ secondsPerDay;
    final remainderAfterDays = totalSeconds % secondsPerDay;
    final hours = remainderAfterDays ~/ 3600;
    final remainderAfterHours = remainderAfterDays % 3600;
    final minutes = remainderAfterHours ~/ 60;
    final seconds = remainderAfterHours % 60;

    return ElapsedBreakdown(
      totalSeconds: totalSeconds,
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
  }

  /// SavedMoney = ElapsedSeconds * ((DailyCount * (PackPrice / PackQuantity)) / 86400)
  static double savedMoney({
    required int elapsedSeconds,
    required int dailyCount,
    required int packPrice,
    required int packQuantity,
  }) {
    if (packQuantity <= 0 || elapsedSeconds <= 0) {
      return 0;
    }

    final perSecondRate =
        (dailyCount * (packPrice / packQuantity)) / secondsPerDay;
    return elapsedSeconds * perSecondRate;
  }

  static List<HealthMilestoneStatus> milestoneStatuses(int elapsedSeconds) {
    return milestones
        .map(
          (milestone) => HealthMilestoneStatus(
            milestone: milestone,
            progressPercent: _progressPercent(elapsedSeconds, milestone.targetSeconds),
            isCompleted: elapsedSeconds >= milestone.targetSeconds,
          ),
        )
        .toList();
  }

  static double _progressPercent(int elapsedSeconds, int targetSeconds) {
    if (targetSeconds <= 0) {
      return 100;
    }
    final raw = (elapsedSeconds / targetSeconds) * 100;
    return raw.clamp(0, 100).toDouble();
  }
}
