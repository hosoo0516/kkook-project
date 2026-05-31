//클래스 다이어그램의 team과 teamMember 관계를 모듈화
// 친구 방 화면에 뿌려줄 핵심 데이터의 구조
import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  final String teamId;
  final String teamName;
  final String inviteCode;
  final List<String> membersList; // 다이어그램의 1..* 관계를 위한 ID 리스트

  Team({
    required this.teamId,
    required this.teamName,
    required this.inviteCode,
    required this.membersList,
  });

  factory Team.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Team(
      teamId: doc.id,
      teamName: data['teamName'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      membersList: List<String>.from(data['membersList'] ?? []),
    );
  }
}

// 다이어그램의 'TeamMember' 클래스
class TeamMember {
  final String userId;
  final String nickname;
  final int currentStreak;  // 현재연속금연일수
  final bool isFailedToday; // 오늘실패여부
  final DateTime? quitStartDate;

  TeamMember({
    required this.userId,
    required this.nickname,
    required this.currentStreak,
    required this.isFailedToday,
    this.quitStartDate,
  });

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    return TeamMember(
      userId: map['userId'] ?? '',
      nickname: map['nickname'] ?? '팀원',
      currentStreak: map['currentStreak'] ?? 0,
      isFailedToday: map['isFailedToday'] ?? false,
      quitStartDate: map['quitStartDate'] != null 
          ? (map['quitStartDate'] as Timestamp).toDate() 
          : null,
      );
  }
}