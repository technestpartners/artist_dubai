import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/models/artist_model.dart';
import 'category_detail_view.dart';

class ExploreCategoriesView extends StatefulWidget {
  const ExploreCategoriesView({super.key});

  @override
  State<ExploreCategoriesView> createState() => _ExploreCategoriesViewState();
}

class _ExploreCategoriesViewState extends State<ExploreCategoriesView> {
  List<CategoryInfo> _categories = ArtistModel.categoryList;
  List<ArtistModel> _allArtists = [];
  StreamSubscription<List<CategoryInfo>>? _catSub;
  StreamSubscription<List<ArtistModel>>? _artistSub;

  @override
  void initState() {
    super.initState();
    _fetchCategoriesFromApi();
    _catSub = sl<LiveSyncService>().categoriesStream.listen((cats) {
      if (mounted) setState(() => _categories = cats);
    });
    _artistSub = sl<LiveSyncService>().artistsStream.listen((artists) {
      if (mounted) setState(() => _allArtists = artists);
    });
  }

  @override
  void dispose() {
    _catSub?.cancel();
    _artistSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchCategoriesFromApi({bool forceRefresh = false}) async {
    try {
      final categories = await sl<ApiService>().getCategories(forceRefresh: forceRefresh);
      final artists = await sl<ApiService>().getArtists(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _categories = categories;
          _allArtists = artists;
        });
      }
    } catch (_) {}
  }

  bool get _isLoggedIn {
    try {
      return sl<StorageService>().getBool('is_logged_in') ?? false;
    } catch (_) {
      return false;
    }
  }

  void _showCreateCategoryModal() {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted) {
        context.push(RouteNames.login);
      }
      return;
    }

    context.push(RouteNames.createCategory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const AppTopBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Sub-Header with Back Button (Matching Screenshot media_1787732660883.png)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1E1E1E),
                      size: 20,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RouteNames.home);
                      }
                    },
                  ),
                  const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF6A2777),
                onRefresh: () => _fetchCategoriesFromApi(forceRefresh: true),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Explore Categories Header Section
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3E8FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.palette_outlined,
                            color: Color(0xFF6A2777),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Explore Categories',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E1E1E),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Discover talented artists',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // + Create Category Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A2777),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _showCreateCategoryModal,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'Create Category',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    ),
                    const SizedBox(height: 20),

                    // 2-Column Grid of Category Cards (Exact Match to Screenshot media_1787732660883.png)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.15,
                          ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final count =
                            _allArtists
                                .where((a) => a.category == category.name)
                                .length;
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => CategoryDetailView(
                                      categoryName: category.name,
                                      emoji: category.emoji,
                                    ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF28208C),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  category.emoji,
                                  style: const TextStyle(fontSize: 30),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  category.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$count artists',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFFD6C8F2),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }
}
