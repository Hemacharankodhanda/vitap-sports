/// VIT-AP Sports — Profile providers (Riverpod).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/models/user_model.dart';
import '../data/profile_service.dart';

/// Profile service provider.
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(supabaseClientProvider));
});

/// Current user's profile — auto-refreshes on auth change.
final currentProfileProvider = FutureProvider<UserModel?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final service = ref.watch(profileServiceProvider);
  return service.getProfile(userId);
});

/// Other user's profile by ID.
final userProfileProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) async {
  final service = ref.watch(profileServiceProvider);
  return service.getProfile(userId);
});

/// Create profile action (used in onboarding).
final createProfileProvider =
    FutureProvider.family<UserModel, Map<String, dynamic>>((ref, data) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) throw Exception('Not authenticated');

  final service = ref.read(profileServiceProvider);
  final profile = await service.createProfile(
    userId: userId,
    name: data['name'] as String,
    branch: data['branch'] as String,
    year: data['year'] as String,
    hostelBlock: data['hostel_block'] as String,
    sportNames: (data['sports'] as List).cast<String>(),
    skillLevels: (data['skill_levels'] as Map).cast<String, String>(),
  );

  ref.invalidate(currentProfileProvider);
  return profile;
});

/// Update profile action.
final updateProfileProvider =
    FutureProvider.family<UserModel, Map<String, dynamic>>((ref, updates) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) throw Exception('Not authenticated');

  final service = ref.read(profileServiceProvider);
  final profile = await service.updateProfile(userId, updates);

  ref.invalidate(currentProfileProvider);
  return profile;
});
