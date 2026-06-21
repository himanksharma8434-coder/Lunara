import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/community_post_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'community_post_card.dart';

class CommunityPostListTab extends StatefulWidget {
  final String category;
  final String searchQuery;
  final String selectedSort;
  final Set<int>? likedPostIds;
  final Map<int, int> optimisticLikesCounts;

  const CommunityPostListTab({
    super.key,
    required this.category,
    required this.searchQuery,
    required this.selectedSort,
    required this.likedPostIds,
    required this.optimisticLikesCounts,
  });

  @override
  State<CommunityPostListTab> createState() => _CommunityPostListTabState();
}

class _CommunityPostListTabState extends State<CommunityPostListTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _dbService = DatabaseService();
  
  List<Map<String, dynamic>> _posts = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 12;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant CommunityPostListTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category ||
        oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.selectedSort != widget.selectedSort) {
      _loadInitialPosts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadInitialPosts() async {
    if (!mounted) return;
    setState(() {
      _isInitialLoading = true;
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      final posts = await _dbService.getCommunityPostsPaged(
        category: widget.category,
        offset: _currentPage * _pageSize,
        limit: _pageSize,
      );
      
      if (mounted) {
        setState(() {
          _posts = posts;
          _isInitialLoading = false;
          _hasMore = posts.length == _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _hasMore = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final posts = await _dbService.getCommunityPostsPaged(
        category: widget.category,
        offset: _currentPage * _pageSize,
        limit: _pageSize,
      );
      
      if (mounted) {
        setState(() {
          _posts.addAll(posts);
          _isLoadingMore = false;
          _hasMore = posts.length == _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _hasMore = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getProcessedPosts() {
    if (widget.searchQuery.isEmpty) return _posts;
    final query = widget.searchQuery.toLowerCase();
    return _posts.where((p) {
      final content = (p['content'] as String?)?.toLowerCase() ?? '';
      final author = (p['author_name'] as String?)?.toLowerCase() ?? '';
      return content.contains(query) || author.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.likedPostIds == null) {
      return const Center(
        child: CircularProgressIndicator(color: LunaraColors.primary),
      );
    }

    if (_isInitialLoading && _posts.isEmpty) {
      return _buildShimmer(context);
    }

    final processedPosts = _getProcessedPosts();

    if (processedPosts.isEmpty) {
      if (widget.searchQuery.isNotEmpty) {
        return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: LunaraColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: LunaraColors.primary.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No results found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try different keywords or check spelling',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.secondaryText(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
      }
      return const Center(child: Text('No posts yet in this category.'));
    }

    return RefreshIndicator(
      color: LunaraColors.primary,
      onRefresh: _loadInitialPosts,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == processedPosts.length) {
                    return _hasMore 
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator(color: LunaraColors.primary)),
                          )
                        : const SizedBox.shrink();
                  }

                  final postModel = CommunityPostModel.fromJson(processedPosts[index]);

                  return RepaintBoundary(
                    child: CommunityPostCard(
                      post: postModel,
                      initialIsLiked: widget.likedPostIds!.contains(postModel.id),
                      initialLikesCount: widget.optimisticLikesCounts[postModel.id],
                      onLikeToggled: (isLiked, newLikesCount) {
                        if (postModel.id != null) {
                          if (isLiked) {
                            widget.likedPostIds!.add(postModel.id!);
                          } else {
                            widget.likedPostIds!.remove(postModel.id!);
                          }
                          widget.optimisticLikesCounts[postModel.id!] = newLikesCount;
                        }
                      },
                    ),
                  );
                },
                childCount: processedPosts.length + (_hasMore ? 1 : 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Shimmer.fromColors(
            baseColor: AppTheme.isDark(context) ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: AppTheme.isDark(context) ? Colors.grey[700]! : Colors.grey[100]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 45, height: 45, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 120, height: 14, color: Colors.white),
                          const SizedBox(height: 6),
                          Container(width: 80, height: 10, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(width: double.infinity, height: 12, color: Colors.white),
                const SizedBox(height: 8),
                Container(width: 200, height: 12, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }
}
