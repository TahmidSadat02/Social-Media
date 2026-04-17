import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../supabase_config.dart';
import '../../features/profile/controllers/profile_controller.dart';
import '../../features/profile/screens/profile_screen.dart';
import 'tab_navigation_service.dart';

void navigateToProfile(BuildContext context, String userId) {
  final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
  if (userId == currentUserId) {
    TabNavigationService.setTabIndex(4);
    Navigator.of(context).popUntil((route) => route.isFirst);
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder:
          (_) => ChangeNotifierProvider(
            create: (_) => ProfileController(),
            child: ProfileScreen(userId: userId),
          ),
    ),
  );
}
