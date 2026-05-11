import '../config/community_supabase_env.dart';

/// Stable entry point for Supabase URL and client keys (matches minimal app setup).
///
/// Values come from `--dart-define`, optional `.vscode/supabase.keys.json`, or env
/// loaders — see [CommunitySupabaseEnv].
abstract final class SupabaseConfig {
  static String get url => CommunitySupabaseEnv.url;

  /// Legacy anon JWT (optional if [publishableKey] is set).
  static String get anonKey => CommunitySupabaseEnv.anonKey;

  /// Preferred for new Supabase projects (`sb_publishable_...`).
  static String get publishableKey => CommunitySupabaseEnv.publishableKey;

  /// Key passed to [Supabase.initialize] — publishable when present, otherwise anon.
  static String get apiKey => CommunitySupabaseEnv.apiKey;

  static bool get isConfigured => CommunitySupabaseEnv.isConfigured;
}
