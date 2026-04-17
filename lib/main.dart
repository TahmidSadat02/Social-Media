import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'supabase_config.dart';
import 'app.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/feed/controllers/feed_controller.dart';
import 'features/profile/controllers/profile_controller.dart';
import 'features/messages/controllers/messages_controller.dart';
import 'features/search/controllers/search_controller.dart'
    as search_controller;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => FeedController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => MessagesController()),
        ChangeNotifierProvider(
          create: (_) => search_controller.SearchController(),
        ),
      ],
      child: const App(),
    ),
  );
}
