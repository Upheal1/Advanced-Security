import 'package:flutter/foundation.dart';

import 'community_supabase_keys_loader_stub.dart'
    if (dart.library.io) 'community_supabase_keys_loader_io.dart' as keys_loader;

/// Supabase project keys — pass at build time:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`
///
/// **Debug / desktop / mobile:** if defines are missing, UpHeal tries to read
/// `.vscode/supabase.keys.json` next to the project (see [tryLoadLocalKeysFile]).
///
/// Web release builds must use `--dart-define` (no local file).
class CommunitySupabaseEnv {
  CommunitySupabaseEnv._();

  static const String _urlDefine = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String _anonDefine = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String _publishableDefine = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static String _urlOverride = '';
  static String _anonOverride = '';
  static String _publishableOverride = '';

  static String get url {
    final o = _urlOverride.trim();
    if (o.isNotEmpty) return o;
    return _urlDefine;
  }

  static String get anonKey {
    final o = _anonOverride.trim();
    if (o.isNotEmpty) return o;
    return _anonDefine;
  }

  static String get publishableKey {
    final o = _publishableOverride.trim();
    if (o.isNotEmpty) return o;
    return _publishableDefine;
  }

  static String get apiKey =>
      publishableKey.isNotEmpty ? publishableKey : anonKey;

  static bool get isConfigured => url.isNotEmpty && apiKey.isNotEmpty;

  /// Merge JSON map from disk into overrides (does not clear defines if map omits a field).
  static void applyFromDiskMap(Map<String, String> map) {
    final u = map['SUPABASE_URL']?.trim() ?? '';
    final pk = map['SUPABASE_PUBLISHABLE_KEY']?.trim() ?? '';
    final an = map['SUPABASE_ANON_KEY']?.trim() ?? '';
    if (u.isNotEmpty) _urlOverride = u;
    if (pk.isNotEmpty) _publishableOverride = pk;
    if (an.isNotEmpty) _anonOverride = an;
  }

  /// Call from [main] before [CommunitySupabase.initializeIfConfigured] (non-web, debug/profile).
  static Future<void> tryLoadLocalKeysFile() async {
    if (kReleaseMode || kIsWeb) return;
    if (isConfigured) return;

    final map = await keys_loader.loadCommunitySupabaseKeysFromDisk();
    if (map == null || map.isEmpty) return;

    applyFromDiskMap(map);
    if (isConfigured) {
      debugPrint('[Community] Loaded Supabase URL/key from .vscode/supabase.keys.json');
    }
  }

  static void debugLogConfig() {
    if (!isConfigured) {
      debugPrint(
        '[Community] Supabase not configured. Use --dart-define, or create '
        '.vscode/supabase.keys.json (see .vscode/supabase.keys.json.example), '
        'or fix Run/Debug configuration — see community_supabase_env.dart.',
      );
    }
  }
}
