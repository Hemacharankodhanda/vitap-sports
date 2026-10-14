/// VIT-AP Sports — Supabase configuration constants.
///
/// Replace these with your actual Supabase project URL and anon key.
library;

class SupabaseConstants {
  SupabaseConstants._();

  static const String url = 'https://neubpyvgzjmilbeajxbv.supabase.co';

  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ldWJweXZnemptaWxiZWFqeGJ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg5Nzc5MjQsImV4cCI6MjEwNDU1MzkyNH0.1fZAC7iWfstybcyAyI8wDKB2rumN2v2D2PGTmiSmzdM';

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
