// lib/screens/community_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_loading.dart';
import '../services/database_service.dart';
import '../models/community_post_model.dart';
import '../models/community_comment_model.dart';
import '../providers/auth_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/custom_toast.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _dbService = DatabaseService();

  // Search state
  bool _isSearchActive = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.15),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
                child: _isSearchActive
                    ? Row(
                        key: const ValueKey('search_bar'),
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: LunaraColors.primary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: LunaraColors.primary.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    color: LunaraColors.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _searchFocusNode,
                                      autofocus: true,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppTheme.textDark(context),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Search posts, authors...',
                                        hintStyle: TextStyle(
                                          color: AppTheme.secondaryText(context),
                                          fontWeight: FontWeight.w400,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryText(context).withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: AppTheme.secondaryText(context),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _searchController.clear();
                              setState(() {
                                _isSearchActive = false;
                              });
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: LunaraColors.primary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('header'),
                        children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          LunaraColors.primary,
                          LunaraColors.primaryDark
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: LunaraColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.people_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Community',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark(context),
                          ),
                        ),
                        Text(
                          'Share, learn, and support',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textLight(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _isSearchActive = true;
                      });
                    },
                    icon: const Icon(Icons.search_rounded),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: LunaraColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _showCreatePostSheet();
                      },
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      tooltip: 'Create Post',
                    ),
                  ),
                        ],
                      ),
              ),
            ),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [LunaraColors.primary, LunaraColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.secondaryText(context),
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'For Women'),
                  Tab(text: 'For Men'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Posts List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsList('Women'),
                  _buildPostsList('Men'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(String category) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _dbService.streamCommunityPosts(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CommunityPostShimmer();
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading posts: ${snapshot.error}'));
        }

        final postsData = snapshot.data ?? [];
        if (postsData.isEmpty) {
          return const Center(child: Text('No posts yet in this category.'));
        }

        // Apply search filter
        final filteredPosts = _searchQuery.isEmpty
            ? postsData
            : postsData.where((postData) {
                final content = (postData['content'] ?? '').toString().toLowerCase();
                final authorName = (postData['author_name'] ?? '').toString().toLowerCase();
                return content.contains(_searchQuery) ||
                    authorName.contains(_searchQuery);
              }).toList();

        if (filteredPosts.isEmpty) {
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

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            final postModel = CommunityPostModel.fromJson(filteredPosts[index]);
            return CommunityPostCard(post: postModel);
          },
        );
      },
    );
  }

  void _showCreatePostSheet() {
    final TextEditingController contentController = TextEditingController();
    String selectedCategory = 'Women';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: AppTheme.background(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    Text(
                      'Create Post',
                      style: TextStyle(
                        color: AppTheme.textDark(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (contentController.text.trim().isEmpty) {
                          CustomToast.show(
                            context,
                            message: 'Please write something',
                            icon: Icons.error_outline_rounded,
                            backgroundColor: Colors.orange[400],
                          );
                          return;
                        }

                        HapticFeedback.mediumImpact();
                        
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final userId = authProvider.userId;
                        final userName = authProvider.userName;
                        if (userId.isNotEmpty) {
                          try {
                            await _dbService.createCommunityPost(
                              authorId: userId,
                              authorName: userName.isNotEmpty ? userName : 'Anonymous',
                              authorAvatar: selectedCategory == 'Women' ? '👩' : '👨',
                              category: selectedCategory,
                              content: contentController.text.trim(),
                            );
                         
                            setState(() {}); // Refresh list

                            if (!context.mounted) return;

                            Navigator.pop(context);
                            CustomToast.show(
                              context,
                              message: 'Post created successfully!',
                              icon: Icons.check_circle_rounded,
                              backgroundColor: const Color(0xFF06D6A0),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            CustomToast.show(
                              context,
                              message: 'Failed to create post: $e',
                              icon: Icons.error_outline_rounded,
                              backgroundColor: Colors.red[400],
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Post',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Selection
                       const Text(
                        'Post Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setModalState(() => selectedCategory = 'Women');
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  gradient: selectedCategory == 'Women'
                                      ? const LinearGradient(
                                          colors: [
                                            LunaraColors.primary,
                                            LunaraColors.primaryDark
                                          ],
                                        )
                                      : null,
                                  color: selectedCategory != 'Women'
                                      ? AppTheme.cardColor(context)
                                      : null,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: selectedCategory == 'Women'
                                        ? Colors.transparent
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.female_rounded,
                                      color: selectedCategory == 'Women'
                                          ? Colors.white
                                          : AppTheme.secondaryText(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Women',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedCategory == 'Women'
                                            ? Colors.white
                                            : AppTheme.secondaryText(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setModalState(() => selectedCategory = 'Men');
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  gradient: selectedCategory == 'Men'
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF118AB2),
                                            LunaraColors.ovulationBlue
                                          ],
                                        )
                                      : null,
                                  color: selectedCategory != 'Men'
                                      ? AppTheme.cardColor(context)
                                      : null,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: selectedCategory == 'Men'
                                        ? Colors.transparent
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.male_rounded,
                                      color: selectedCategory == 'Men'
                                          ? Colors.white
                                          : AppTheme.secondaryText(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Men',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedCategory == 'Men'
                                            ? Colors.white
                                            : AppTheme.secondaryText(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Content Input
                      const Text(
                        'What\'s on your mind?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor(context),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          controller: contentController,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            hintText:
                                'Share your experience, ask questions, or offer support...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommunityPostCard extends StatefulWidget {
  final CommunityPostModel post;

  const CommunityPostCard({super.key, required this.post});

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard> {
  final DatabaseService _dbService = DatabaseService();
  bool? _isLikedLocal;
  int? _likesCountLocal;

  @override
  void didUpdateWidget(CommunityPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _isLikedLocal = null;
      _likesCountLocal = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userId;

    return FutureBuilder<bool>(
      future: _isLikedLocal != null
          ? Future.value(_isLikedLocal)
          : _dbService.hasUserLikedPost(widget.post.id!, currentUserId),
      builder: (context, snapshot) {
        final isLiked = _isLikedLocal ?? snapshot.data ?? false;
        final likesCount = _likesCountLocal ?? widget.post.likesCount;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.post.category == 'Women'
                            ? [LunaraColors.primary, const Color(0xFFFFB4A9)]
                            : [const Color(0xFF118AB2), LunaraColors.ovulationBlue],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.post.authorAvatar ?? (widget.post.category == 'Women' ? '👩' : '👨'),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.authorName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark(context),
                          ),
                        ),
                        Text(
                          timeago.format(widget.post.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.post.category == 'Women'
                          ? LunaraColors.primary.withOpacity(0.15)
                          : const Color(0xFF118AB2).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.post.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.post.category == 'Women'
                            ? LunaraColors.primaryDark
                            : const Color(0xFF118AB2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                widget.post.content,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLight(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (currentUserId.isEmpty) return;
                      HapticFeedback.lightImpact();
                      final oldIsLiked = isLiked;
                      final oldLikesCount = likesCount;
                      setState(() {
                        _isLikedLocal = !oldIsLiked;
                        _likesCountLocal = oldLikesCount + (oldIsLiked ? -1 : 1);
                      });
                      try {
                        await _dbService.toggleLikePost(widget.post.id!, currentUserId, oldIsLiked);
                      } catch (e) {
                        setState(() {
                          _isLikedLocal = oldIsLiked;
                          _likesCountLocal = oldLikesCount;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLiked
                            ? LunaraColors.primary.withOpacity(0.15)
                            : AppTheme.isDark(context) ? const Color(0xFF2A2A2A) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: isLiked ? LunaraColors.primary : AppTheme.secondaryText(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$likesCount',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isLiked ? LunaraColors.primaryDark : AppTheme.secondaryText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showCommentsSheet(context, widget.post);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.isDark(context) ? const Color(0xFF2A2A2A) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 18, color: AppTheme.secondaryText(context)),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.post.commentCount}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.secondaryText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                    },
                    icon: Icon(Icons.share_outlined, size: 20, color: AppTheme.secondaryText(context)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCommentsSheet(BuildContext context, CommunityPostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheetContent(post: post),
    );
  }
}

// A stateful widget for the comments sheet to handle real-time fetching and posting
class _CommentsSheetContent extends StatefulWidget {
  final CommunityPostModel post;

  const _CommentsSheetContent({required this.post});

  @override
  State<_CommentsSheetContent> createState() => _CommentsSheetContentState();
}

class _CommentsSheetContentState extends State<_CommentsSheetContent> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _commentController = TextEditingController();

  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final comments = await _dbService.getComments(widget.post.id!);
    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    final userName = authProvider.userName;

    if (userId.isNotEmpty) {
      final tempComment = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'post_id': widget.post.id,
        'author_id': userId,
        'author_name': userName.isNotEmpty ? userName : 'Anonymous',
        'author_avatar': widget.post.category == 'Women' ? '👩' : '👨',
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
      };

      setState(() {
        _comments.add(tempComment);
      });
      _commentController.clear();

      try {
        await _dbService.addComment(
          postId: widget.post.id!,
          authorId: userId,
          authorName: userName.isNotEmpty ? userName : 'Anonymous',
          authorAvatar: widget.post.category == 'Women' ? '👩' : '👨',
          content: text,
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _comments.removeWhere((c) => c['id'] == tempComment['id']);
          });
          CustomToast.show(
            context,
            message: 'Failed to post comment',
            icon: Icons.error_outline_rounded,
            backgroundColor: Colors.red[400],
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text(
                  '${_isLoading ? widget.post.commentCount : _comments.length} Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark(context),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Comments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 15),
                            Text(
                              'No comments yet',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to comment',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final commentData = _comments[index];
                    final comment = CommunityCommentModel.fromJson(commentData);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: AppTheme.isDark(context)
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                comment.authorAvatar ?? '👤',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor(context),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        comment.authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        timeago.format(comment.createdAt),
                                        style: TextStyle(
                                          color: AppTheme.secondaryText(context),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    comment.content,
                                    style: TextStyle(
                                      color: AppTheme.textLight(context),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),

          // Comment Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.inputFillColor(context),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        LunaraColors.primary,
                        LunaraColors.primaryDark
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _submitComment,
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
