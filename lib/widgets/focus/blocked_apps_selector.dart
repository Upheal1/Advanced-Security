import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// App category presets for quick selection
class AppPreset {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> packageNames;

  const AppPreset({
    required this.name,
    required this.icon,
    required this.color,
    required this.packageNames,
  });
}

/// Default app presets
const List<AppPreset> defaultPresets = [
  AppPreset(
    name: 'Social Media',
    icon: LucideIcons.share2,
    color: Color(0xFFE91E63),
    packageNames: [
      'com.instagram.android',
      'com.facebook.katana',
      'com.twitter.android',
      'com.zhiliaoapp.musically', // TikTok
      'com.snapchat.android',
      'com.linkedin.android',
      'com.pinterest',
      'com.reddit.frontpage',
    ],
  ),
  AppPreset(
    name: 'Games',
    icon: LucideIcons.gamepad2,
    color: Color(0xFF9C27B0),
    packageNames: [
      'com.supercell.clashofclans',
      'com.supercell.clashroyale',
      'com.roblox.client',
      'com.kiloo.subwaysurf',
      'com.mojang.minecraftpe',
      'com.pubg.mobile',
      'com.garena.game.codm',
    ],
  ),
  AppPreset(
    name: 'Video & Streaming',
    icon: LucideIcons.play,
    color: Color(0xFFFF5722),
    packageNames: [
      'com.google.android.youtube',
      'com.netflix.mediaclient',
      'com.amazon.avod.thirdpartyclient',
      'com.disney.disneyplus',
      'tv.twitch.android.app',
      'com.hulu.plus',
    ],
  ),
  AppPreset(
    name: 'Messaging',
    icon: LucideIcons.messageCircle,
    color: Color(0xFF4CAF50),
    packageNames: [
      'com.whatsapp',
      'com.facebook.orca', // Messenger
      'org.telegram.messenger',
      'com.discord',
      'com.Slack',
      'com.viber.voip',
    ],
  ),
  AppPreset(
    name: 'All Distractions',
    icon: LucideIcons.shieldOff,
    color: Color(0xFFF44336),
    packageNames: [], // This will combine all presets
  ),
];

/// Widget for selecting apps to block during focus sessions
class BlockedAppsSelector extends StatefulWidget {
  final List<String> selectedApps;
  final ValueChanged<List<String>> onSelectionChanged;
  final List<Map<String, dynamic>>? installedApps;

  const BlockedAppsSelector({
    super.key,
    required this.selectedApps,
    required this.onSelectionChanged,
    this.installedApps,
  });

  @override
  State<BlockedAppsSelector> createState() => _BlockedAppsSelectorState();
}

class _BlockedAppsSelectorState extends State<BlockedAppsSelector> {
  late Set<String> _selectedApps;
  bool _showCustomApps = false;

  @override
  void initState() {
    super.initState();
    _selectedApps = Set.from(widget.selectedApps);
  }

  @override
  void didUpdateWidget(BlockedAppsSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedApps != oldWidget.selectedApps) {
      _selectedApps = Set.from(widget.selectedApps);
    }
  }

  void _toggleApp(String packageName) {
    setState(() {
      if (_selectedApps.contains(packageName)) {
        _selectedApps.remove(packageName);
      } else {
        _selectedApps.add(packageName);
      }
    });
    widget.onSelectionChanged(_selectedApps.toList());
  }

  void _selectPreset(AppPreset preset) {
    setState(() {
      if (preset.name == 'All Distractions') {
        // Select all apps from all presets
        for (final p in defaultPresets) {
          if (p.name != 'All Distractions') {
            _selectedApps.addAll(p.packageNames);
          }
        }
      } else {
        // Toggle the preset
        final hasAll = preset.packageNames.every((p) => _selectedApps.contains(p));
        if (hasAll) {
          _selectedApps.removeAll(preset.packageNames);
        } else {
          _selectedApps.addAll(preset.packageNames);
        }
      }
    });
    widget.onSelectionChanged(_selectedApps.toList());
  }

  void _clearAll() {
    setState(() {
      _selectedApps.clear();
    });
    widget.onSelectionChanged([]);
  }

  bool _isPresetSelected(AppPreset preset) {
    if (preset.name == 'All Distractions') {
      // Check if all apps from all presets are selected
      for (final p in defaultPresets) {
        if (p.name != 'All Distractions') {
          if (!p.packageNames.every((pkg) => _selectedApps.contains(pkg))) {
            return false;
          }
        }
      }
      return true;
    }
    return preset.packageNames.every((p) => _selectedApps.contains(p));
  }

  bool _isPresetPartiallySelected(AppPreset preset) {
    if (preset.name == 'All Distractions') return false;
    final selected = preset.packageNames.where((p) => _selectedApps.contains(p)).length;
    return selected > 0 && selected < preset.packageNames.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.shield,
                    color: Color(0xFF7C3AED),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Block Distractions',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '${_selectedApps.length} apps selected',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedApps.isNotEmpty)
                  TextButton(
                    onPressed: _clearAll,
                    child: Text(
                      'Clear',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Quick presets
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Select',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: defaultPresets.map((preset) {
                    final isSelected = _isPresetSelected(preset);
                    final isPartial = _isPresetPartiallySelected(preset);
                    
                    return _PresetChip(
                      preset: preset,
                      isSelected: isSelected,
                      isPartiallySelected: isPartial,
                      onTap: () => _selectPreset(preset),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Show/hide custom apps toggle
          if (widget.installedApps != null && widget.installedApps!.isNotEmpty)
            Column(
              children: [
                const Divider(height: 1),
                ListTile(
                  onTap: () => setState(() => _showCustomApps = !_showCustomApps),
                  leading: Icon(
                    _showCustomApps ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                    size: 20,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  title: Text(
                    'Select Individual Apps',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  trailing: Text(
                    '${widget.installedApps!.length} available',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
                if (_showCustomApps)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.installedApps!.length,
                      itemBuilder: (context, index) {
                        final app = widget.installedApps![index];
                        final packageName = app['packageName'] as String? ?? '';
                        final appName = app['appName'] as String? ?? packageName;
                        final isSelected = _selectedApps.contains(packageName);

                        return ListTile(
                          dense: true,
                          onTap: () => _toggleApp(packageName),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.1) 
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              LucideIcons.box,
                              size: 18,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                          title: Text(
                            appName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleApp(packageName),
                            activeColor: const Color(0xFF7C3AED),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),

          // Save preferences hint
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 16,
                    color: const Color(0xFF7C3AED).withOpacity(0.8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your selection will be saved for future sessions',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

/// Preset selection chip
class _PresetChip extends StatelessWidget {
  final AppPreset preset;
  final bool isSelected;
  final bool isPartiallySelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.preset,
    required this.isSelected,
    required this.isPartiallySelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? preset.color
              : isPartiallySelected
                  ? preset.color.withOpacity(0.3)
                  : preset.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected || isPartiallySelected
                ? preset.color
                : preset.color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              preset.icon,
              size: 16,
              color: isSelected ? Colors.white : preset.color,
            ),
            const SizedBox(width: 6),
            Text(
              preset.name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : preset.color,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check_circle,
                size: 14,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact blocked apps summary for display
class BlockedAppsSummary extends StatelessWidget {
  final List<String> blockedApps;
  final VoidCallback? onEdit;

  const BlockedAppsSummary({
    super.key,
    required this.blockedApps,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (blockedApps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.shieldOff,
              size: 18,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No apps blocked during session',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            if (onEdit != null)
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Add',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7C3AED).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.shield,
              size: 16,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${blockedApps.length} apps blocked',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Will be blocked during session',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: Icon(
                LucideIcons.pencil,
                size: 16,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
        ],
      ),
    );
  }
}
