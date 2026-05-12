// lib/services/auth_service.dart
import '../features/community/services/community_supabase.dart';

/// Thin Supabase auth wrapper used across the app.
/// Delegates to [CommunitySupabase.clientOrNull] so it is compatible with the
/// lazy-initialisation pattern already in use.
class AuthService {
  /// Sign in with email and password.
  /// Throws [AuthException] (supabase_flutter) on failure.
  Future<void> signIn(String email, String password) async {
    await CommunitySupabase.clientOrNull?.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Create a new account with email and password.
  /// Throws [AuthException] (supabase_flutter) on failure.
  Future<void> signUp(String email, String password) async {
    await CommunitySupabase.clientOrNull?.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await CommunitySupabase.clientOrNull?.auth.signOut();
  }

  /// Returns the current user's UUID, or `null` if not signed in.
  String? get currentUserId =>
      CommunitySupabase.clientOrNull?.auth.currentUser?.id;

  /// Returns the current user's email, or `null` if not signed in.
  String? get currentUserEmail =>
      CommunitySupabase.clientOrNull?.auth.currentUser?.email;

  /// Returns `true` if a user is currently signed in.
  bool get isSignedIn =>
      CommunitySupabase.clientOrNull?.auth.currentUser != null;
}
