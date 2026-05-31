// 다이어그램의 user 클래스 구조
// 서버에서 받은 데이터 Dart 객체로 변환하는 역할
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String userId;
  final String email;
  final String nickname;
  final String mode; // ModeType 대용 (IMMEDIATE_QUIT, GRADUAL_REDUCTION)
  final DateTime createdAt;

  User({
    required this.userId,
    required this.email,
    required this.nickname,
    required this.mode,
    required this.createdAt,
  });

  // Firebase(JSON 형태)에서 데이터를 가져와 복사본을 만드는 생성자
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      userId: doc.id,
      email: data['email'] ?? '',
      nickname: data['nickname'] ?? '닉네임 없음',
      mode: data['mode'] ?? 'IMMEDIATE_QUIT',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}