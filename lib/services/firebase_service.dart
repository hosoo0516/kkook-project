import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🕵️‍♂️ [추가된 핵심 메서드] 현재 로그인한 유저가 참여 중인 방이 이미 존재하는지 체크
  Future<String?> checkUserJoinedTeam() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // 1. 내가 방장(leaderId)인 방이 있는지 먼저 조회합니다.
      final ledTeams = await _db
          .collection('teams')
          .where('leaderId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (ledTeams.docs.isNotEmpty) {
        return ledTeams.docs.first.id; // 내가 방장인 방 ID 반환
      }

      // 2. 내가 멤버로 참여 중인 방이 있는지 서브컬렉션 그룹 쿼리로 조회합니다.
      final memberGroup = await _db
          .collectionGroup('members')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (memberGroup.docs.isNotEmpty) {
        // members 문서의 상위 teams 문서 ID를 가져옴
        final teamDocRef = memberGroup.docs.first.reference.parent.parent;
        return teamDocRef?.id;
      }

      return null; // 가입된 방이 아무것도 없음
    } catch (e) {
      print('가입 방 조회 실패: $e');
      return null;
    }
  }

  /// 🤝 방 생성 로직 (이미 방이 있으면 기존 방 ID 리턴)
  Future<String> createTeam(String teamName) async {
    final user = _auth.currentUser; // 현재 로그인한 구글 유저 정보 통째로 가져오기
    if (user == null) throw Exception('구글 로그인이 필요합니다.');

    try {
      // 🕵️‍♂️ 이미 내가 '방장'으로 참여하고 있는 기존 방이 있는지 먼저 조회
      final existingTeams = await _db
          .collection('teams')
          .where('leaderId', isEqualTo: user.uid)
          .limit(1)
          .get();

      // 이미 기존에 만들어 둔 방이 존재한다면 기존 ID 그대로 반환
      if (existingTeams.docs.isNotEmpty) {
        return existingTeams.docs.first.id;
      }

      // 기존 방이 없을 때만 새 방 생성
      final teamDocRef = _db.collection('teams').doc();
      final teamId = teamDocRef.id;

      // 방 기본 정보 생성
      await teamDocRef.set({
        'teamId': teamId,
        'teamName': teamName,
        'createdAt': FieldValue.serverTimestamp(),
        'leaderId': user.uid, // 방장 구글 UID
      });

      // 🚪 방을 만든 나 자신을 멤버 컬렉션에 구글 프로필 기반으로 등록!
      await teamDocRef.collection('members').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? '익명의 사용자', // 구글 이름 반영
        'photoUrl': user.photoURL ?? '',         // 구글 프로필 사진 반영
        'joinedAt': FieldValue.serverTimestamp(),
        'currentStreak': 0,
      });

      return teamId; // 친구에게 알려줄 초대 코드(방 ID)
      
    } catch (e) {
      throw Exception('방 생성 및 조회 중 에러 발생: $e');
    }
  }

  /// 🚪 초대 코드를 입력해 다른 사람의 방에 입장하는 로직
  Future<void> joinTeam(String teamId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('구글 로그인이 필요합니다.');

    try {
      final teamDocRef = _db.collection('teams').doc(teamId);
      final teamSnapshot = await teamDocRef.get();

      if (!teamSnapshot.exists) {
        throw Exception('존재하지 않는 초대 코드입니다.');
      }

      // 해당 방의 멤버 서브컬렉션에 내 정보 등록
      await teamDocRef.collection('members').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? '익명의 사용자',
        'photoUrl': user.photoURL ?? '',
        'joinedAt': FieldValue.serverTimestamp(),
        'currentStreak': 0,
      });
    } catch (e) {
      throw Exception('방 입장 실패: $e');
    }
  }
  /// 🚪 가입된 금연방에서 나가는 로직 (방장이면 방 폭파, 멤버면 나만 퇴장)
  Future<void> leaveTeam(String teamId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('구글 로그인이 필요합니다.');

    try {
      final teamDocRef = _db.collection('teams').doc(teamId);
      final teamSnapshot = await teamDocRef.get();

      if (teamSnapshot.exists) {
        final teamData = teamSnapshot.data() as Map<String, dynamic>;
        String? leaderId = teamData['leaderId'];

        // 1️⃣ 만약 내가 '방장'이라면? -> 방 자체를 삭제 (멤버 서브컬렉션까지 청소)
        if (leaderId == user.uid) {
          // members 서브컬렉션 안의 문서들 먼저 다 지우기
          final membersSnapshot = await teamDocRef.collection('members').get();
          for (var doc in membersSnapshot.docs) {
            await doc.reference.delete();
          }
          // 메인 팀 문서 삭제
          await teamDocRef.delete();
        } 
        // 2️⃣ 내가 일반 '멤버'라면? -> 내 프로필 문서만 서브컬렉션에서 삭제
        else {
          await teamDocRef.collection('members').doc(user.uid).delete();
        }
      }
    } catch (e) {
      throw Exception('방 나가기 실패: $e');
    }
  }
}