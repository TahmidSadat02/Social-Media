import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/utils/tab_navigation_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/feed/screens/feed_screen.dart';
import 'features/feed/screens/create_photo_post_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/messages/screens/messages_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/feed/controllers/feed_controller.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    TabNavigationService.tabIndex.addListener(_syncTabFromService);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().initialize();
    });
  }

  @override
  void dispose() {
    TabNavigationService.tabIndex.removeListener(_syncTabFromService);
    super.dispose();
  }

  void _syncTabFromService() {
    if (!mounted) {
      return;
    }
    setState(() {
      _currentTabIndex = TabNavigationService.tabIndex.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        // Show login screen if not authenticated
        if (!authController.isAuthenticated) {
          return MaterialApp(
            home: const LoginScreen(),
            routes: {'/login': (context) => const LoginScreen()},
            theme: _buildTheme(),
            debugShowCheckedModeBanner: false,
          );
        }

        // Show main app with bottom nav if authenticated
        return MaterialApp(
          home: _MainApp(
            currentUserId: authController.currentUser!.id,
            currentTabIndex: _currentTabIndex,
            onTabChanged: (index) {
              setState(() {
                _currentTabIndex = index;
              });
              TabNavigationService.setTabIndex(index);
            },
          ),
          routes: {'/login': (context) => const LoginScreen()},
          theme: _buildTheme(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MainApp extends StatefulWidget {
  final String currentUserId;
  final int currentTabIndex;
  final Function(int) onTabChanged;

  const _MainApp({
    required this.currentUserId,
    required this.currentTabIndex,
    required this.onTabChanged,
  });

  @override
  State<_MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<_MainApp> {
  late List<Widget> _screens;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _screens = [
      const FeedScreen(),
      const SearchScreen(),
      const SizedBox.shrink(),
      const MessagesScreen(),
      ProfileScreen(userId: widget.currentUserId),
    ];
  }

  Future<void> _handleCreatePhotoPostTap() async {
    final authController = context.read<AuthController>();
    final user = authController.currentUser;
    if (user == null) {
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null || !mounted) {
      return;
    }

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CreatePhotoPostScreen(imagePath: picked.path),
      ),
    );

    if (created == true && mounted) {
      await context.read<FeedController>().loadPosts(user.id);
      widget.onTabChanged(0);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post shared successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: widget.currentTabIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.currentTabIndex,
        onTap: (index) {
          if (index == 2) {
            _handleCreatePhotoPostTap();
            return;
          }
          widget.onTabChanged(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.muted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
