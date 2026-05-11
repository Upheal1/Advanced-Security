import 'dart:convert';
import 'dart:io';

/// Reads [.vscode/supabase.keys.json] relative to the process working directory.
Future<Map<String, String>?> loadCommunitySupabaseKeysFromDisk() async {
  final names = [
    File('.vscode${Platform.pathSeparator}supabase.keys.json'),
    File(
      'frontend-main${Platform.pathSeparator}.vscode${Platform.pathSeparator}supabase.keys.json',
    ),
    File(
      '..${Platform.pathSeparator}.vscode${Platform.pathSeparator}supabase.keys.json',
    ),
  ];

  for (final f in names) {
    try {
      if (!await f.exists()) continue;
      final raw = jsonDecode(await f.readAsString());
      if (raw is! Map) continue;
      final out = <String, String>{};
      for (final e in raw.entries) {
        final v = e.value;
        if (v != null) out[e.key.toString()] = v.toString().trim();
      }
      final url = out['SUPABASE_URL'] ?? '';
      final pk = out['SUPABASE_PUBLISHABLE_KEY'] ?? '';
      final anon = out['SUPABASE_ANON_KEY'] ?? '';
      if (url.isNotEmpty && (pk.isNotEmpty || anon.isNotEmpty)) {
        return out;
      }
    } catch (_) {
      continue;
    }
  }
  return null;
}
