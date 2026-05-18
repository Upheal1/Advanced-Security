# Code Cleanup Report

## 1. Unused Imports (可以直接删除)

### Community Feature
| File | Line | Unused Import |
|------|------|----------------|
| `lib/features/community/ui/community_post_card.dart` | 3 | `flutter_animate` |

### Screens
| File | Line | Unused Import |
|------|------|----------------|
| `lib/screens/analytics_screen.dart` | 2 | `dart:math` |
| `lib/screens/analytics_screen.dart` | 12 | `../main.dart` |
| `lib/screens/analytics_screen.dart` | 14 | `../services/export_service.dart` |
| `lib/screens/analytics_screen.dart` | 27 | `insight_card.dart` |
| `lib/screens/community_screen.dart` | 7 | `../main.dart` |
| `lib/screens/mini_games_screen.dart` | 6 | `../main.dart` |
| `lib/screens/parental_control_screen.dart` | 7 | `../main.dart` |
| `lib/screens/sleep_tracker_screen.dart` | 9 | `../main.dart` |

### Services
| File | Line | Unused Import |
|------|------|----------------|
| `lib/services/export_service.dart` | 2 | `dart:typed_data` |
| `lib/services/export_service.dart` | 10 | `intl/intl.dart` |
| `lib/services/insights_service.dart` | 7 | `screen_time_model.dart` |
| `lib/services/notification_service.dart` | 1 | `dart:ui` |

---

## 2. Unused Elements (可以直接删除)

### Community Feature
| File | Line | Element | Type |
|------|------|---------|------|
| `lib/features/community/ui/community_post_card.dart` | 317 | `_MiniBadge` | Class |
| `lib/features/community/ui/community_post_card.dart` | 670 | `_ActionIcon` | Class |
| `lib/features/community/ui/community_post_card.dart` | 675 | `filled` param | Parameter |
| `lib/features/community/ui/community_post_card.dart` | 676 | `color` param | Parameter |
| `lib/features/community/ui/feed_tab.dart` | 703 | `_NewPostsBanner` | Class |

### Screens
| File | Line | Element | Type |
|------|------|---------|------|
| `lib/screens/analytics_screen.dart` | 1173 | `_buildFocusScoreCard` | Method |
| `lib/screens/analytics_screen.dart` | 1972 | `_loadWeeklyTrendData` | Method |
| `lib/screens/gad_phq_form_screen.dart` | 94 | `_progress` | Element |
| `lib/screens/badges_screen.dart` | 404 | Dead null aware | Expression |

---

## 3. Unused Variables (可以直接删除或修复)

| File | Line | Variable | Type |
|------|------|----------|------|
| `lib/features/community/ui/compose_post_screen.dart` | 79 | `scheme` | Local variable |
| `lib/features/community/ui/feed_tab.dart` | 673 | `scheme` | Local variable |
| `lib/screens/analytics_screen.dart` | 401 | `cardColor` | Local variable |
| `lib/services/ai_insight_generator.dart` | 22 | `now` | Local variable |
| `lib/services/ai_insight_generator.dart` | 239 | `changePercent` | Local variable |
| `lib/services/ai_insight_generator.dart` | 337 | `peakDay` | Local variable |
| `lib/services/insights_service.dart` | 198 | `totalSleep` | Local variable |
| `lib/services/insights_service.dart` | 217 | `totalScreen` | Local variable |
| `lib/widgets/comparison/comparison_card.dart` | 312 | `isDark` | Local variable |
| `lib/widgets/streak/streak_freeze_dialog.dart` | 427 | `isDark` | Local variable |

---

## 4. Unused Fields (可以直接删除)

| File | Line | Field |
|------|------|-------|
| `lib/services/ai_insight_generator.dart` | 9 | `_habitThreshold` |
| `lib/services/insights_service.dart` | 16 | `_significantChangeThreshold` |
| `lib/services/insights_service.dart` | 17 | `_highUsageThreshold` |
| `lib/services/insights_service.dart` | 18 | `_lowUsageThreshold` |
| `lib/services/insights_service.dart` | 19 | `_peakHourThreshold` |

---

## 5. Other Issues

| File | Line | Issue |
|------|------|-------|
| `lib/services/vpn_controller.dart` | 14 | Unused catch clause |
| `lib/config.dart` | - | Constants not in lowerCamelCase (naming convention) |
| `lib/features/steps/services/step_permission_service.dart` | Multiple | `print()` statements in production code |
| `lib/features/steps/services/step_sensor_service.dart` | Multiple | `print()` statements in production code |

---

## 6. Deprecated withOpacity (建议替换为 withValues)

共有 **60+ 处** 使用了已弃用的 `withOpacity`，分布在多个文件中：
- `lib/avatar/` - 5处
- `lib/features/community/` - 30+处
- 其他文件

建议批量替换: `.withOpacity(x)` → `.withValues(alpha: x)`

---

## 建议优先级

1. **高优先级** - 删除未使用的 imports 和 elements (最简单)
2. **中优先级** - 删除未使用的 variables 和 fields
3. **低优先级** - 修复 deprecated withOpacity (工作量较大)
4. **可选** - 修复 print() 语句和命名规范