
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  /// Get the current session, if any.
  Session? get currentSession => _client.auth.currentSession;

  /// Get the current user, if any.
  User? get currentUser => _client.auth.currentUser;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with Google OAuth.
  /// The server-side trigger will reject non-VIT-AP emails.
  Future<bool> signInWithGoogle() async {
    final result = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.vitap.vitapsports://login-callback/',
    );
    return result;
  }

  /// Sign out and clear session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Check if the current user's email is from the allowed domains.
  bool isAllowedDomain() {
    final email = currentUser?.email;
    if (email == null) return false;
    
    return SupabaseConstants.allowedEmailDomains.any(
      (domain) => email.endsWith('@$domain'),
    );
  }

  /// Check if user has completed onboarding (profile exists in public.users).
  Future<bool> hasCompletedOnboarding() async {
    final userId = currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('users')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    return response != null;
  }
}
