import 'package:cloud_firestore/cloud_firestore.dart';

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
    // 점진적 감소 모드용 추가 필드 (기존 유저 에러 방지를 위해 nullable 처리)
    this.remainingSmokes,
    this.lastSmokeDate,
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
    if (currentMode != null) data['currentMode'] = currentMode;
    if (remainingSmokes != null) data['remainingSmokes'] = remainingSmokes;
    if (lastSmokeDate != null) data['lastSmokeDate'] = Timestamp.fromDate(lastSmokeDate!);
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
  }) {
    return UserConfig(
      uid: uid,
      smokingStartYear: smokingStartYear ?? this.smokingStartYear,
      dailyCount: dailyCount ?? this.dailyCount,
      packPrice: packPrice ?? this.packPrice,
      packQuantity: packQuantity ?? this.packQuantity,
      quitStartDate: quitStartDate ?? this.quitStartDate,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      currentMode: clearCurrentMode ? null : (currentMode ?? this.currentMode),
      remainingSmokes: remainingSmokes ?? this.remainingSmokes,
      lastSmokeDate: lastSmokeDate ?? this.lastSmokeDate,
    );
  }

  static UserConfig? fromFirestore(String uid, Map<String, dynamic> data) {
    final quitStart = data['quitStartDate'];
    if (quitStart is! Timestamp) return null;

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
      remainingSmokes: data['remainingSmokes'] != null ? _asInt(data['remainingSmokes']) : null,
      lastSmokeDate: lastSmoke is Timestamp ? lastSmoke.toDate() : null,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- 기존 함수들 (변경 없음) ---
  Future<void> saveUserConfig(UserConfig config) async {
    await _firestore
        .collection('users')
        .doc(config.uid)
        .set(config.toFirestore(), SetOptions(merge: true));
  }

  Stream<UserConfig?> watchUserConfig(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return UserConfig.fromFirestore(uid, data);
    });
  }

  Future<bool> isOnboardingCompleted(String uid) async {
    final config = await getUserConfig(uid);
    return config?.isOnboardingCompleted == true;
  }

  Future<UserConfig?> getUserConfig(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;
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
    final data = mode == null
        ? {'currentMode': FieldValue.delete()}
        : {'currentMode': mode};
    await _firestore.collection('users').doc(uid).set(
          data,
          SetOptions(merge: true),
        );
  }

  // --- 🔥 새로 추가된 점진적 모드 전용 함수 ---

  /// 유저의 현재 제한량과 남은 개수를 계산해 반환하고, 날이 바뀌었으면 리셋합니다.
 /// 유저의 현재 제한량과 남은 개수를 계산해 반환하고, 날이 바뀌었으면 리셋합니다.
  Future<Map<String, dynamic>> syncAndGetGradualData(String uid) async {
    final config = await getUserConfig(uid);
    if (config == null) throw Exception("유저 데이터를 찾을 수 없습니다.");

    final now = DateTime.now();
    // 온보딩에서 입력한 초기 하루 흡연량 (기본값 10)
    final initialLimit = config.dailyCount > 0 ? config.dailyCount : 10;
    
    // 7일(1주)마다 -10%씩 감소하는 로직
    final int daysPassed = now.difference(config.quitStartDate).inDays;
    final int weeksPassed = daysPassed ~/ 7;
    
    double reductionRate = 1.0 - (0.10 * weeksPassed);
    if (reductionRate < 0.1) reductionRate = 0.1; // 최소 10% 방어선

    int currentTotalLimit = (initialLimit * reductionRate).round();
    if (currentTotalLimit <= 0) currentTotalLimit = 1; // 최소 1개비 보장

    // 🚨 년(year), 월(month), 일(day)을 모두 정확하게 비교하도록 수정
    bool isNewDay = config.lastSmokeDate == null || 
                    config.lastSmokeDate!.year != now.year || // 👈 년도 체크 추가!
                    config.lastSmokeDate!.month != now.month || 
                    config.lastSmokeDate!.day != now.day;

    int remaining = config.remainingSmokes ?? currentTotalLimit;

    // 만약 날이 바뀌었거나, DB의 남은 개수가 null이거나 오류로 인해 0인 경우 최초 1회 강제 초기화
    if (isNewDay || config.remainingSmokes == null) {
      remaining = currentTotalLimit;
      await _firestore.collection('users').doc(uid).set({
        'remainingSmokes': remaining,
        'lastSmokeDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return {
      'currentTotalLimit': currentTotalLimit,
      'remainingSmokes': remaining,
    };
  }

  /// 트랜잭션을 사용하여 동시성 문제(타이밍 꼬임) 없이 흡연 횟수를 1개 차감합니다.
  Future<bool> deductSmokeCount(String uid) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference userRef = _firestore.collection('users').doc(uid);
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (!snapshot.exists) throw Exception("유저 없음");

        int currentRemaining = snapshot.get('remainingSmokes') ?? 0;
        if (currentRemaining <= 0) throw Exception("잔여 횟수 없음");

        transaction.update(userRef, {
          'remainingSmokes': currentRemaining - 1,
          'lastSmokeDate': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}