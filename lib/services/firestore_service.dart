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
  });

  final String uid;
  final int smokingStartYear;
  final int dailyCount;
  final int packPrice;
  final int packQuantity;
  final DateTime quitStartDate;
  final bool isOnboardingCompleted;
  final String? currentMode;

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
    );
  }

  static UserConfig? fromFirestore(String uid, Map<String, dynamic> data) {
    final quitStart = data['quitStartDate'];
    if (quitStart is! Timestamp) {
      return null;
    }

    final mode = data['currentMode'];
    return UserConfig(
      uid: uid,
      smokingStartYear: _asInt(data['smokingStartYear']),
      dailyCount: _asInt(data['dailyCount']),
      packPrice: _asInt(data['packPrice']),
      packQuantity: _asInt(data['packQuantity']),
      quitStartDate: quitStart.toDate(),
      isOnboardingCompleted: data['isOnboardingCompleted'] == true,
      currentMode: mode is String ? mode : null,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
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
    final data = mode == null
        ? {'currentMode': FieldValue.delete()}
        : {'currentMode': mode};
    await _firestore.collection('users').doc(uid).set(
          data,
          SetOptions(merge: true),
        );
  }
}
