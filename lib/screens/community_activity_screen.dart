import 'package:flutter/material.dart';
import 'package:lunara/models/community_post_model.dart';
import 'package:lunara/services/database_service.dart';
import 'package:lunara/services/saved_posts_service.dart';
import 'package:lunara/theme/app_theme.dart';
import 'package:lunara/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:lunara/widgets/community_post_card.dart';

class CommunityActivityScreen extends StatelessWidget {
  const CommunityActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background(context),
        appBar: AppBar(
          title: Text(
            'Community Activity',
            style: TextStyle(
              color: AppTheme.textDark(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark(context)),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            labelColor: LunaraColors.primary,
            unselectedLabelColor: AppTheme.secondaryText(context),
            indicatorColor: LunaraColors.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'My Posts'),
              Tab(text: 'Saved Posts'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MyPostsTab(),
            _SavedPostsTab(),
          ],
        ),
      ),
    );
  }
}

class _MyPostsTab extends StatefulWidget {
  const _MyPostsTab();

  @override
  State<_MyPostsTab> createState() => _MyPostsTabState();
}

class _MyPostsTabState extends State<_MyPostsTab> {
  bool _isLoading = true;
  List<CommunityPostModel> _posts = [];
  Set<int> _likedPostIds = {};

  @override
  void initState() {
    super.initState();
    _loadMyPosts();
  }

  Future<void> _loadMyPosts() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final postsData = await DatabaseService().getUserPosts(authProvider.userId);
      final likedIds = await DatabaseService().getUserLikedPostIds(authProvider.userId);

      if (mounted) {
        setState(() {
          _posts = postsData.map((e) => CommunityPostModel.fromJson(e)).toList();
          _likedPostIds = likedIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading my posts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePost(int postId) async {
    try {
      final authProvider = context.read<AuthProvider>();
      await DatabaseService().deleteCommunityPost(postId, authProvider.userId);
      setState(() {
        _posts.removeWhere((p) => p.id == postId);
      });
    } catch (e) {
      debugPrint('Error deleting post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: LunaraColors.primary),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.post_add_rounded,
              size: 80,
              color: AppTheme.secondaryText(context).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share something with the community!',
              style: TextStyle(
                color: AppTheme.textLight(context),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: LunaraColors.primary,
      onRefresh: _loadMyPosts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _posts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final post = _posts[index];
          return CommunityPostCard(
            key: ValueKey('my_post_${post.id}'),
            post: post,
            initialIsLiked: _likedPostIds.contains(post.id),
            onDelete: () => _deletePost(post.id ?? 0),
          );
        },
      ),
    );
  }
}

class _SavedPostsTab extends StatefulWidget {
  const _SavedPostsTab();

  @override
  State<_SavedPostsTab> createState() => _SavedPostsTabState();
}

class _SavedPostsTabState extends State<_SavedPostsTab> {
  bool _isLoading = true;
  List<CommunityPostModel> _posts = [];
  Set<int> _likedPostIds = {};

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
    SavedPostsService.instance.addListener(_onSavedPostsChanged);
  }

  @override
  void dispose() {
    SavedPostsService.instance.removeListener(_onSavedPostsChanged);
    super.dispose();
  }

  void _onSavedPostsChanged() {
    _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    setState(() => _isLoading = true);
    final savedIds = SavedPostsService.instance.savedPostIds.toList();

    if (savedIds.isEmpty) {
      setState(() {
        _posts = [];
        _likedPostIds = {};
        _isLoading = false;
      });
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final postsData = await DatabaseService().getPostsByIds(savedIds);
      final likedIds = await DatabaseService().getUserLikedPostIds(authProvider.userId);

      if (mounted) {
        setState(() {
          _posts = postsData.map((e) => CommunityPostModel.fromJson(e)).toList();
          _likedPostIds = likedIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved posts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: LunaraColors.primary),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 80,
              color: AppTheme.secondaryText(context).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No saved posts yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Posts you bookmark will appear here.',
              style: TextStyle(
                color: AppTheme.textLight(context),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: LunaraColors.primary,
      onRefresh: _loadSavedPosts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _posts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final post = _posts[index];
          return CommunityPostCard(
            key: ValueKey('saved_post_${post.id}'),
            post: post,
            initialIsLiked: _likedPostIds.contains(post.id),
          );
        },
      ),
    );
  }
}
