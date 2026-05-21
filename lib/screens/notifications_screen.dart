// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'community_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  bool _isOpeningPost = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _markNotificationsAsRead();
  }

  void _loadNotifications() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _notificationsFuture = _dbService.getRepliesToUserPosts(authProvider.userId);
  }

  Future<void> _markNotificationsAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_notifications_view_time', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  Future<void> _openPostComments(int postId) async {
    if (_isOpeningPost) return;
    setState(() => _isOpeningPost = true);

    try {
      HapticFeedback.mediumImpact();
      final post = await _dbService.getCommunityPostById(postId);
      setState(() => _isOpeningPost = false);

      if (post != null && mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => CommentsSheetContent(post: post),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load post. It may have been deleted.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => _isOpeningPost = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildAvatar(String? avatarUrl, String name) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(avatarUrl),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: LunaraColors.primary.withOpacity(0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: LunaraColors.primaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.textDark(context);

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: Stack(
        children: [
          // Background layout
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.backgroundGradient(context),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor(context),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppTheme.softShadow(context),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Replies to your community posts',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textLight(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Notifications list
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _notificationsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: LunaraColors.primary,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load notifications',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _loadNotifications();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: LunaraColors.primary,
                                ),
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        );
                      }

                      final items = snapshot.data ?? [];

                      if (items.isEmpty) {
                        return RefreshIndicator(
                          color: LunaraColors.primary,
                          onRefresh: () async {
                            setState(() {
                              _loadNotifications();
                            });
                          },
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: LunaraColors.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.notifications_none_rounded,
                                        size: 48,
                                        color: LunaraColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'All caught up!',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No replies to your posts yet.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textLight(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: LunaraColors.primary,
                        onRefresh: () async {
                          setState(() {
                            _loadNotifications();
                          });
                        },
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final name = item['author_name'] ?? 'Someone';
                            final avatarUrl = item['author_avatar'];
                            final rawContent = item['content'] ?? '';
                            final content = rawContent.startsWith('[reply:') && rawContent.contains(']')
                                ? rawContent.substring(rawContent.indexOf(']') + 1)
                                : rawContent;
                            final postId = item['post_id'] as int;
                            final createdAt = DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor(context),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: AppTheme.softShadow(context),
                                border: Border.all(
                                  color: AppTheme.divider(context),
                                  width: 1.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _openPostComments(postId),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildAvatar(avatarUrl, name),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                RichText(
                                                  text: TextSpan(
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: textColor,
                                                      height: 1.3,
                                                    ),
                                                    children: [
                                                      TextSpan(
                                                        text: name,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const TextSpan(
                                                        text: ' replied to your community post',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  content,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: AppTheme.textBrown(context).withOpacity(0.8),
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  timeago.format(createdAt),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.textLight(context),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: AppTheme.textLight(context),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isOpeningPost)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: LunaraColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
