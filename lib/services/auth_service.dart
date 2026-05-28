import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/auth_config.dart';

class SignInResult {
  const SignInResult({this.user, this.errorMessage});

  final User? user;
  final String? errorMessage;

  bool get isSuccess => user != null;

  bool get isCompleted => errorMessage == null;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final GoogleSignIn _googleSignIn = _createGoogleSignIn();

  GoogleSignIn _createGoogleSignIn() {
    if (kIsWeb) {
      final clientId = AuthConfig.googleWebClientId;
      if (clientId != null && clientId.isNotEmpty) {
        return GoogleSignIn(clientId: clientId, scopes: ['email']);
      }
    }
    return GoogleSignIn(scopes: ['email']);
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<SignInResult> signInWithGoogle() async {
    if (kIsWeb &&
        (AuthConfig.googleWebClientId == null ||
            AuthConfig.googleWebClientId!.isEmpty)) {
      return const SignInResult(
        errorMessage:
            '웹 Google 로그인: lib/config/auth_config.dart에 googleWebClientId를 설정해 주세요.',
      );
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const SignInResult(errorMessage: '로그인이 취소되었습니다.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return SignInResult(user: userCredential.user);
    } on FirebaseAuthException catch (e) {
      return SignInResult(
        errorMessage: _firebaseMessage(e),
      );
    } catch (e) {
      return SignInResult(errorMessage: 'Google 로그인 중 오류: $e');
    }
  }

  Future<SignInResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      return const SignInResult(errorMessage: '이메일과 비밀번호를 입력해 주세요.');
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      return SignInResult(user: credential.user);
    } on FirebaseAuthException catch (e) {
      return SignInResult(errorMessage: _firebaseMessage(e));
    }
  }

  Future<SignInResult> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();

    if (trimmedName.isEmpty) {
      return const SignInResult(errorMessage: '이름을 입력해 주세요.');
    }
    if (trimmedEmail.isEmpty || password.isEmpty) {
      return const SignInResult(errorMessage: '이메일과 비밀번호를 입력해 주세요.');
    }
    if (password.length < 6) {
      return const SignInResult(errorMessage: '비밀번호는 6자 이상이어야 합니다.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      await credential.user?.updateDisplayName(trimmedName);
      return SignInResult(user: credential.user);
    } on FirebaseAuthException catch (e) {
      return SignInResult(errorMessage: _firebaseMessage(e));
    }
  }

  Future<SignInResult> sendPasswordResetEmail(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return const SignInResult(errorMessage: '이메일을 입력해 주세요.');
    }

    try {
      await _auth.sendPasswordResetEmail(email: trimmedEmail);
      return const SignInResult();
    } on FirebaseAuthException catch (e) {
      return SignInResult(errorMessage: _firebaseMessage(e));
    }
  }

  Future<void> signOut() async {
    await Future.wait([_googleSignIn.signOut(), _auth.signOut()]);
  }

  String _firebaseMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return '올바른 이메일 형식이 아닙니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'weak-password':
        return '비밀번호가 너무 약합니다.';
      case 'operation-not-allowed':
        return 'Firebase Console에서 해당 로그인 방식을 활성화해 주세요.';
      default:
        return e.message ?? '인증 오류 (${e.code})';
    }
  }
}
