/// Firebase Console → 프로젝트 설정 → 일반 → 내 앱 → Web 앱
/// 또는 Authentication → Google → Web SDK 의 OAuth 2.0 Web client ID
///
/// `flutterfire configure` 실행 후 [lib/firebase_options.dart]의 값도
/// 실제 프로젝트 값으로 교체해야 로그인이 동작합니다.
class AuthConfig {
  static const String? googleWebClientId = '366143800773-9ho3p0v1funfh8kesi9ev30nte2udj9d.apps.googleusercontent.com';
}
