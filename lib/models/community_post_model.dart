/// Represents a community post in the social feed.
class CommunityPostModel {
  final int? id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String category; // 'Women', 'Men'
  final String content;
  final int likesCount;
  final int commentCount;
  final bool isLikedByUser;
  final DateTime createdAt;

  CommunityPostModel({
    this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.category,
    required this.content,
    this.likesCount = 0,
    this.commentCount = 0,
    this.isLikedByUser = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: json['id'],
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? 'Anonymous',
      authorAvatar: json['author_avatar'],
      category: json['category'] ?? 'Women',
      content: json['content'] ?? '',
      likesCount: json['likes_count'] ?? 0,
      commentCount: json['comments_count'] ?? 0,
      isLikedByUser: json['isLikedByUser'] ?? false, // Handled separately or via RPC
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'category': category,
      'content': content,
      'likes_count': likesCount,
      'comments_count': commentCount,
      // isLikedByUser is typically not saved directly to the posts table
      'created_at': createdAt.toIso8601String(),
    };
  }

  CommunityPostModel copyWith({
    int? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? category,
    String? content,
    int? likesCount,
    int? commentCount,
    bool? isLikedByUser,
    DateTime? createdAt,
  }) {
    return CommunityPostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      category: category ?? this.category,
      content: content ?? this.content,
      likesCount: likesCount ?? this.likesCount,
      commentCount: commentCount ?? this.commentCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
