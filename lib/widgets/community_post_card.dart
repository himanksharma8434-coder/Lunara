import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/community_post_model.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../screens/community_screen.dart';


class CommunityPostCard extends StatefulWidget {
  final CommunityPostModel post;
  final bool initialIsLiked;
  final int? initialLikesCount;
  final Function(bool, int)? onLikeToggled;
  final VoidCallback? onDelete;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.initialIsLiked,
    this.initialLikesCount,
    this.onLikeToggled,
    this.onDelete,
  });

  @override
  State<CommunityPostCard> createState() => CommunityPostCardState();
}

class CommunityPostCardState extends State<CommunityPostCard>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final ValueNotifier<({bool liked, int count})> _likeState;
  late final ValueNotifier<int> _commentCount;
  final DatabaseService _dbService = DatabaseService();
  bool _isLikeProcessing = false;

  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnim;
  late Animation<double> _heartOpacityAnim;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    int initialCount = widget.initialLikesCount ?? widget.post.likesCount;
    // Fallback: if the database hasn't updated likes_count but the user liked it,
    // ensure it shows at least 1 like.
    if (widget.initialIsLiked && initialCount == 0) {
      initialCount = 1;
    }
    _likeState = ValueNotifier((
      liked: widget.initialIsLiked,
      count: initialCount,
    ));
    _commentCount = ValueNotifier(widget.post.commentCount);

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _heartScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0).chain(CurveTween(curve: Curves.linear)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
    ]).animate(_heartAnimController);

    _heartOpacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0).chain(CurveTween(curve: Curves.linear)), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
    ]).animate(_heartAnimController);
  }

  @override
  void didUpdateWidget(CommunityPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      int updatedCount = widget.initialLikesCount ?? widget.post.likesCount;
      if (widget.initialIsLiked && updatedCount == 0) {
        updatedCount = 1;
      }
      _likeState.value = (
        liked: widget.initialIsLiked,
        count: updatedCount,
      );
      _commentCount.value = widget.post.commentCount;
    } else {
      if (!_isLikeProcessing && oldWidget.post.likesCount != widget.post.likesCount) {
        int newCount = widget.post.likesCount;
        if (_likeState.value.liked && newCount == 0) {
          newCount = 1;
        }
        _likeState.value = (
          liked: _likeState.value.liked,
          count: newCount,
        );
      }
      if (oldWidget.post.commentCount != widget.post.commentCount) {
        _commentCount.value = widget.post.commentCount;
      }
    }
  }

  /// Call this from the comments sheet to increment the count optimistically.
  void incrementCommentCount() {
    _commentCount.value = _commentCount.value + 1;
  }

  @override
  void dispose() {
    _likeState.dispose();
    _commentCount.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  Future<void> _handleLike() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userId;
    if (currentUserId.isEmpty || _isLikeProcessing) return;

    _isLikeProcessing = true;
    HapticFeedback.lightImpact();

    final old = _likeState.value;
    final newLiked = !old.liked;
    final newCount = (old.count + (old.liked ? -1 : 1)).clamp(0, 999999);

    _likeState.value = (liked: newLiked, count: newCount);
    widget.onLikeToggled?.call(newLiked, newCount);

    try {
      await _dbService.toggleLikePost(widget.post.id!, currentUserId, old.liked);
    } catch (e) {
      if (mounted) {
        _likeState.value = old;
        widget.onLikeToggled?.call(old.liked, old.count);
      }
    } finally {
      if (mounted) {
        _isLikeProcessing = false;
      }
    }
  }

  void _handleDoubleTap() {
    if (!_likeState.value.liked) {
      _handleLike();
    }
    _heartAnimController.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _showCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CommentsSheetContent(
        post: widget.post,
        onCommentAdded: () {
          incrementCommentCount();
        },
      ),
    );
  }

  int _lastTapTime = 0;

  void _handlePointerDown(PointerDownEvent event) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTapTime < 300) {
      _handleDoubleTap();
      _lastTapTime = 0;
    } else {
      _lastTapTime = now;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for KeepAlive

    return Listener(
      onPointerDown: _handlePointerDown,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
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
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: widget.post.authorAvatar != null && widget.post.authorAvatar!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.post.authorAvatar!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.person, size: 20, color: Colors.grey),
                                ),
                                errorWidget: (context, url, error) => _buildDefaultAvatar(),
                              )
                            : _buildDefaultAvatar(),
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
                    if (context.read<AuthProvider>().userId == widget.post.authorId && widget.onDelete != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  'Delete Post?',
                                  style: TextStyle(
                                    color: AppTheme.textDark(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to delete this post? This action cannot be undone.',
                                  style: TextStyle(
                                    color: AppTheme.secondaryText(context),
                                  ),
                                ),
                                backgroundColor: AppTheme.cardColor(context),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: AppTheme.secondaryText(context),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && widget.onDelete != null) {
                              widget.onDelete!();
                            }
                          },
                          child: Icon(Icons.delete_outline_rounded, color: AppTheme.secondaryText(context), size: 20),
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
                    ValueListenableBuilder<({bool liked, int count})>(
                      valueListenable: _likeState,
                      builder: (context, state, _) {
                        return GestureDetector(
                          onTap: _handleLike,
                          child: Row(
                            children: [
                              Icon(
                                state.liked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                color: state.liked ? Colors.redAccent : AppTheme.secondaryText(context),
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                state.count.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: state.liked ? Colors.redAccent : AppTheme.secondaryText(context),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: _showCommentsBottomSheet,
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppTheme.secondaryText(context),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          ValueListenableBuilder<int>(
                            valueListenable: _commentCount,
                            builder: (context, count, _) {
                              return Text(
                                count.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.secondaryText(context),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Double tap heart animation overlay
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _heartAnimController,
              builder: (context, child) {
                if (_heartAnimController.value == 0.0) return const SizedBox.shrink();
                return Opacity(
                  opacity: _heartOpacityAnim.value,
                  child: Transform.scale(
                    scale: _heartScaleAnim.value,
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 100,
                      shadows: [
                        Shadow(color: Colors.black26, blurRadius: 20)
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: widget.post.category == 'Women'
          ? LunaraColors.primary.withOpacity(0.2)
          : const Color(0xFF118AB2).withOpacity(0.2),
      child: Center(
        child: Text(
          widget.post.authorName.isNotEmpty ? widget.post.authorName[0].toUpperCase() : '?',
          style: TextStyle(
            color: widget.post.category == 'Women' ? LunaraColors.primaryDark : const Color(0xFF118AB2),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
