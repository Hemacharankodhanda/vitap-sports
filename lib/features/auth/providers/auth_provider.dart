/// VIT-AP Sports — Auth providers (Riverpod).
///
/// Providers for auth state, current user, sign-in/sign-out actions.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_service.dart';

/// Supabase client singleton.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Auth service provider.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

/// Reactive auth state — emits on login/logout.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges;
});

/// Current session (nullable).
final currentSessionProvider = Provider<Session?>((ref) {
  return ref.watch(authServiceProvider).currentSession;
});

/// Current user (nullable).
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.session?.user;
});

/// Current user ID (nullable).
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.id;
});

/// Whether user is logged in.
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});


/// Sign in action.
final signInProvider = FutureProvider.autoDispose<bool>((ref) async {
  final service = ref.read(authServiceProvider);
  return service.signInWithGoogle();
});

/// Sign out action.
final signOutProvider = FutureProvider.autoDispose<void>((ref) async {
  final service = ref.read(authServiceProvider);
  await service.signOut();
});
