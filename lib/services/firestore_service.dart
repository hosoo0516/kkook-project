import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserMode {
  static const String coldTurkey = 'cold_turkey';
  static const String gradual = 'gradual';
}

class UserConfig {
  const UserConfig({
    required this.uid,
    required this.smokingStartYear,
    required this.dailyCount,
    required this.packPrice,
    required this.packQuantity,
    required this.quitStartDate,
    this.isOnboardingCompleted = true,
    this.currentMode,
    this.remainingSmokes,
    this.lastSmokeDate,
    this.lastDailyResetKey,
  });

  final String uid;
  final int smokingStartYear;
  final int dailyCount;
  final int packPrice;
  final int packQuantity;
  final DateTime quitStartDate;
  final bool isOnboardingCompleted;
  final String? currentMode;
  final int? remainingSmokes;
  final DateTime? lastSmokeDate;
  final String? lastDailyResetKey;

  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'uid': uid,
      'smokingStartYear': smokingStartYear,
      'dailyCount': dailyCount,
      'packPrice': packPrice,
      'packQuantity': packQuantity,
      'quitStartDate': Timestamp.fromDate(quitStartDate),
      'isOnboardingCompleted': isOnboardingCompleted,
    };
    if (currentMode != null) {
      data['currentMode'] = currentMode;
    }
    if (remainingSmokes != null) {
      data['remainingSmokes'] = remainingSmokes;
    }
    if (lastSmokeDate != null) {
      data['lastSmokeDate'] = Timestamp.fromDate(lastSmokeDate!);
    }
    if (lastDailyResetKey != null) {
      data['lastDailyResetKey'] = lastDailyResetKey;
    }
    return data;
  }

  UserConfig copyWith({
    int? smokingStartYear,
    int? dailyCount,
    int? packPrice,
    int? packQuantity,
    DateTime? quitStartDate,
    bool? isOnboardingCompleted,
    String? currentMode,
    bool clearCurrentMode = false,
    int? remainingSmokes,
    DateTime? lastSmokeDate,
    String? lastDailyResetKey,
  }) {
    return UserConfig(
      uid: uid,
      smokingStartYear: smokingStartYear ?? this.smokingStartYear,
      dailyCount: dailyCount ?? this.dailyCount,
      packPrice: packPrice ?? this.packPrice,
      packQuantity: packQuantity ?? this.packQuantity,
      quitStartDate: quitStartDate ?? this.quitStartDate,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      currentMode: clearCurrentMode ? null : (currentMode ?? this.currentMode),
      remainingSmokes: remainingSmokes ?? this.remainingSmokes,
      lastSmokeDate: lastSmokeDate ?? this.lastSmokeDate,
      lastDailyResetKey: lastDailyResetKey ?? this.lastDailyResetKey,
    );
  }

  static UserConfig? fromFirestore(String uid, Map<String, dynamic> data) {
    final quitStart = data['quitStartDate'];
    if (quitStart is! Timestamp) {
      return null;
    }

    final mode = data['currentMode'];
    final lastSmoke = data['lastSmokeDate'];

    return UserConfig(
      uid: uid,
      smokingStartYear: _asInt(data['smokingStartYear']),
      dailyCount: _asInt(data['dailyCount']),
      packPrice: _asInt(data['packPrice']),
      packQuantity: _asInt(data['packQuantity']),
      quitStartDate: quitStart.toDate(),
      isOnboardingCompleted: data['isOnboardingCompleted'] == true,
      currentMode: mode is String ? mode : null,
      remainingSmokes: data['remainingSmokes'] != null
          ? _asInt(data['remainingSmokes'])
          : null,
      lastSmokeDate: lastSmoke is Timestamp ? lastSmoke.toDate() : null,
      lastDailyResetKey: data['lastDailyResetKey'] as String?,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}

class GradualLimits {
  const GradualLimits({
    required this.currentTotalLimit,
    required this.reductionPercent,
  });

  final int currentTotalLimit;
  final double reductionPercent;
}

/// AuthGate 라우팅 전용 — remainingSmokes 변경 시 화면 재생성 방지
enum AppRoute {
  onboarding,
  modeSelect,
  coldTurkey,
  gradual,
}

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserConfig(UserConfig config) async {
    await _firestore
        .collection('users')
        .doc(config.uid)
        .set(config.toFirestore(), SetOptions(merge: true));
  }

  Stream<UserConfig?> watchUserConfig(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return UserConfig.fromFirestore(uid, data);
    });
  }

  /// 온보딩/모드 변경 시에만 분기. 차감(remainingSmokes) 업데이트는 무시.
  Stream<AppRoute> watchAppRoute(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      return _resolveAppRoute(snapshot.data());
    }).distinct();
  }

  AppRoute _resolveAppRoute(Map<String, dynamic>? data) {
    if (data == null || data['isOnboardingCompleted'] != true) {
      return AppRoute.onboarding;
    }
    final mode = data['currentMode'];
    if (mode is! String || mode.isEmpty) {
      return AppRoute.modeSelect;
    }
    if (mode == UserMode.coldTurkey) {
      return AppRoute.coldTurkey;
    }
    if (mode == UserMode.gradual) {
      return AppRoute.gradual;
    }
    return AppRoute.modeSelect;
  }

  static const Duration _firestoreOpTimeout = Duration(seconds: 20);

  Future<bool> isOnboardingCompleted(String uid) async {
    final config = await getUserConfig(uid);
    return config?.isOnboardingCompleted == true;
  }

  Future<UserConfig?> getUserConfig(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return UserConfig.fromFirestore(uid, data);
  }

  Future<void> updateQuitStartDate({
    required String uid,
    required DateTime quitStartDate,
  }) async {
    await _firestore.collection('users').doc(uid).set(
      {'quitStartDate': Timestamp.fromDate(quitStartDate)},
      SetOptions(merge: true),
    );
  }

  Future<void> updateUserMode(String uid, String? mode) async {
    if (mode == null) {
      await _firestore.collection('users').doc(uid).set(
        {'currentMode': FieldValue.delete()},
        SetOptions(merge: true),
      );
      return;
    }

    final updates = <String, dynamic>{'currentMode': mode};

    if (mode == UserMode.gradual) {
      final config = await getUserConfig(uid);
      if (config != null) {
        final limits = calculateGradualLimits(config, DateTime.now());
        updates['remainingSmokes'] = limits.currentTotalLimit;
        updates['lastDailyResetKey'] = _dateKey(DateTime.now());
      }
    }

    await _firestore.collection('users').doc(uid).set(
          updates,
          SetOptions(merge: true),
        );
  }

  GradualLimits calculateGradualLimits(UserConfig config, DateTime now) {
    final initialLimit = config.dailyCount > 0 ? config.dailyCount : 10;
    final daysPassed = now.difference(config.quitStartDate).inDays;
    final weeksPassed = daysPassed ~/ 7;

    var reductionRate = 1.0 - (0.10 * weeksPassed);
    if (reductionRate < 0.1) {
      reductionRate = 0.1;
    }

    var currentTotalLimit = (initialLimit * reductionRate).round();
    if (currentTotalLimit <= 0) {
      currentTotalLimit = 1;
    }

    final reductionPercent = ((1.0 - reductionRate) * 100).clamp(0.0, 90.0);

    return GradualLimits(
      currentTotalLimit: currentTotalLimit,
      reductionPercent: reductionPercent,
    );
  }

  Future<Map<String, dynamic>> syncAndGetGradualData(String uid) async {
    final docRef = _firestore.collection('users').doc(uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('유저 데이터를 찾을 수 없습니다.');
    }

    final data = snapshot.data()!;
    final config = UserConfig.fromFirestore(uid, data);
    if (config == null) {
      throw Exception('유저 설정을 읽을 수 없습니다.');
    }

    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final limits = calculateGradualLimits(config, now);
    final totalLimit = limits.currentTotalLimit;

    final lastResetKey = data['lastDailyResetKey'] as String?;
    final needsReset =
        lastResetKey != todayKey || data['remainingSmokes'] == null;

    var remaining = UserConfig._asInt(data['remainingSmokes']);
    if (needsReset) {
      remaining = totalLimit;
      await docRef.set(
        {
          'remainingSmokes': remaining,
          'lastDailyResetKey': todayKey,
        },
        SetOptions(merge: true),
      );
    }

    return {
      'currentTotalLimit': totalLimit,
      'remainingSmokes': remaining,
      'reductionPercent': limits.reductionPercent,
    };
  }

  /// UI 표시값 기준 1회 write. 웹 long-polling + set(merge) 사용.
  Future<String?> deductSmokeCount(
    String uid, {
    required int fromRemaining,
  }) async {
    if (fromRemaining <= 0) {
      return '금일 한도가 소진되었습니다.';
    }

    final docRef = _firestore.collection('users').doc(uid);
    final payload = <String, dynamic>{
      'remainingSmokes': fromRemaining - 1,
      'lastSmokeDate': Timestamp.fromDate(DateTime.now()),
    };

    try {
      await _firestore.enableNetwork();
      await FirebaseAuth.instance.currentUser?.getIdToken(true);

      await docRef
          .set(payload, SetOptions(merge: true))
          .timeout(_firestoreOpTimeout);

      return null;
    } on TimeoutException {
      return 'timeout';
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Firestore 권한이 없습니다. 보안 규칙을 확인해 주세요.';
      }
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        return 'timeout';
      }
      return e.message ?? 'Firestore 오류 (${e.code})';
    } catch (e) {
      return e.toString();
    }
  }

  static String _dateKey(DateTime dateTime) {
    return '${dateTime.year}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }
}
