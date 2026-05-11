import 'package:flutter/material.dart';

import 'community_groups_tab.dart';

/// Thin alias so layouts can import `groups_tab.dart` alongside [FeedTab].
class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context) => const CommunityGroupsTab();
}
