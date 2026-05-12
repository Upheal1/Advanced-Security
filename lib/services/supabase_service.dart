import '../features/community/services/community_supabase.dart';

/// Thin wrapper around [CommunitySupabase] that exposes the Supabase JWT
/// access token needed to authenticate requests to the Upheal backend.
///
/// The Supabase Flutter SDK automatically refreshes the session token before
/// it expires; reading [currentSession?.accessToken] always returns a valid
/// token as long as the user is signed in.
abstract final class SupabaseService {
  SupabaseService._();

  /// Returns the current Supabase JWT access token, or [null] when the user
  /// is not signed in or Supabase has not been initialised.
  static Future<String?> get idToken async {
    return CommunitySupabase.clientOrNull?.auth.currentSession?.accessToken;
  }

  /// Returns the authenticated user's UUID, or [null] when not signed in.
  static String? get userId =>
      CommunitySupabase.clientOrNull?.auth.currentUser?.id;
}
