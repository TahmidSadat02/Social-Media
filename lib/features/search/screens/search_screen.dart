import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/initials.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../controllers/search_controller.dart' as search_controller;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Search', style: AppTextStyles.heading3),
        centerTitle: true,
      ),
      body: Consumer<search_controller.SearchController>(
        builder: (context, searchController, _) {
          return Column(
            children: [
              // Search field
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  style: AppTextStyles.bodyMedium,
                  onChanged: (query) {
                    searchController.searchUsers(query);
                  },
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: AppColors.muted),
                    hintText: 'Search users...',
                    hintStyle: AppTextStyles.bodySmall,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.muted),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.muted),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              // Search results
              Expanded(
                child:
                    searchController.isSearching
                        ? Center(
                          child: CircularProgressIndicator(
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.accent,
                            ),
                          ),
                        )
                        : searchController.searchResults.isEmpty &&
                            _searchController.text.isEmpty
                        ? Center(
                          child: Text(
                            'Search for users',
                            style: AppTextStyles.bodySmall,
                          ),
                        )
                        : searchController.searchResults.isEmpty
                        ? Center(
                          child: Text(
                            'No users found',
                            style: AppTextStyles.bodySmall,
                          ),
                        )
                        : ListView.builder(
                          itemCount: searchController.searchResults.length,
                          itemBuilder: (context, index) {
                            final user = searchController.searchResults[index];
                            final initials = getInitials(
                              user.fullName.trim().isNotEmpty
                                  ? user.fullName
                                  : user.username,
                            );

                            return GestureDetector(
                              onTap: () {
                                navigateToProfile(context, user.id);
                              },
                              child: Container(
                                color: AppColors.surface,
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 1),
                                child: Row(
                                  children: [
                                    AvatarWidget(
                                      imageUrl: user.avatarUrl,
                                      initials: initials,
                                      size: 50,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.username,
                                            style: AppTextStyles.bodyLarge,
                                          ),
                                          Text(
                                            user.fullName,
                                            style: AppTextStyles.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: AppColors.muted,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}
