/// VIT-AP Sports — Supabase configuration constants.
///
/// Replace these with your actual Supabase project URL and anon key.
library;

class SupabaseConstants {
  SupabaseConstants._();

  static const String url = 'supabase url';

  static const String anonKey = 'supabase anon key';

  // Storage bucket names
  static const String avatarsBucket = 'avatars';
  static const String teamLogosBucket = 'team-logos';

  // VIT-AP email domains for auth restriction
  static const List<String> allowedEmailDomains = ['vitap.ac.in', 'vitapstudent.ac.in'];

  // Google OAuth provider
  static const String googleProvider = 'google';

  // Realtime channels
  static const String scorecardChannel = 'scorecard-updates';

  // Pagination
  static const int defaultPageSize = 20;
}
