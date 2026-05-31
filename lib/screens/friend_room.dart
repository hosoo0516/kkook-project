import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import '../theme/kkook_theme.dart';

class FriendRoomPage extends StatefulWidget {
  const FriendRoomPage({super.key});

  @override
  State<FriendRoomPage> createState() => _FriendRoomPageState();
}

class _FriendRoomPageState extends State<FriendRoomPage> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _teamId;
  bool _isChecking = true;
  
  late Timer _timer;
  
  @override
  void initState() {
    super.initState();
    _loadTeamId();

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {}); 
    });

  }
  
  @override
  void dispose() {
    _timer.cancel(); 
    super.dispose();
  }

  Future<void> _loadTeamId() async {
    String? teamId = await _firebaseService.checkUserJoinedTeam();
    if (mounted) {
      setState(() {
        _teamId = teamId;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: KkookColors.background,
        body: Center(child: CircularProgressIndicator(color: KkookColors.primary)),
      );
    }

    if (_teamId == null) {
      return Scaffold(
        backgroundColor: KkookColors.background,
        appBar: AppBar(title: const Text('실시간 친구 금연방'), backgroundColor: KkookColors.background),
        body: const Center(child: Text('참여 중인 금연방이 없습니다.')),
      );
    }

    return Scaffold(
      backgroundColor: KkookColors.background,
      appBar: AppBar(
        title: const Text('🤝 실시간 친구 금연방'),
        centerTitle: true,
        backgroundColor: KkookColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black87),
            tooltip: '방 나가기',
            onPressed: _showLeaveDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: KkookColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📢 친구 초대 코드 (방 ID)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: KkookColors.primary)),
                        const SizedBox(height: 6),
                        SelectableText(_teamId!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: KkookColors.primary),
                    tooltip: '초대 코드 복사',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _teamId!));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('초대 코드가 클립보드에 복사되었습니다!')));
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .doc(_teamId)
                  .collection('members')
                  .orderBy('joinedAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('오류가 발생했습니다.'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: KkookColors.primary));
                }

                final members = snapshot.data?.docs ?? [];

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final memberData = members[index].data() as Map<String, dynamic>;
                    String name = memberData['name'] ?? '익명';
                    String photoUrl = memberData['photoUrl'] ?? '';
                    int streak = memberData['currentStreak'] ?? 0;

                    // 🕒 금연 시간 계산 로직
                    Timestamp? joinedAt = memberData['joinedAt'] as Timestamp?;
                    String timeText = '금연 기록 없음';
                    if (joinedAt != null) {
                      DateTime startTime = joinedAt.toDate();
                      Duration diff = DateTime.now().difference(startTime);
                      timeText = '${diff.inDays}일 ${diff.inHours % 24}시간 ${diff.inMinutes % 60}분째 금연 중 🔥';
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: KkookColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: KkookColors.primary.withOpacity(0.1),
                            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                            child: photoUrl.isEmpty ? const Icon(Icons.person_rounded, color: KkookColors.primary) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  '현재 $streak일째 / $timeText',
                                  style: const TextStyle(fontSize: 12, color: KkookColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('🚪 방 나가기', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('정말 이 금연방에서 나가시겠습니까?\n(방장일 경우 방이 완전히 폭파됩니다.)'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  if (_teamId != null) {
                    await _firebaseService.leaveTeam(_teamId!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('금연방에서 성공적으로 퇴장했습니다.')));
                      Navigator.pop(context);
                    }
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('방 나가기 실패: $e')));
                }
              },
              child: const Text('나가기', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}