import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_config.dart';
import '../../../config/community_supabase_env.dart';

/// Lazily initializes Supabase when URL + anon key are provided.
class CommunitySupabase {
  CommunitySupabase._();

  static bool _initialized = false;

  static Future<void> initializeIfConfigured() async {
    if (_initialized) return;
    if (!SupabaseConfig.isConfigured) {
      CommunitySupabaseEnv.debugLogConfig();
      return;
    }
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.apiKey,
      debug: kDebugMode,
    );
    _initialized = true;
    debugPrint('[Community] Supabase initialized.');
  }

  static bool get isReady => _initialized;

  /// Null until [initializeIfConfigured] succeeds.
  static SupabaseClient? get clientOrNull =>
      _initialized ? Supabase.instance.client : null;
}
