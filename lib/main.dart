import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // 윈도우 개발자 모드가 켜져 있어야 이 아래 코드가 에러 없이 돌아가!
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('KKOOK 테스트 앱')),
        body: const Center(child: Text('Firebase 연동 성공!! 🥳')),
      ),
    );
  }
}