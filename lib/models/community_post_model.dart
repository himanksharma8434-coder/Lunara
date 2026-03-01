/// Represents a community post in the social feed.
class CommunityPostModel {
  final int? id;
  final String authorName;
  final String? authorAvatar;
  final String category; // 'General', 'Tips', 'Support', 'Question'
  final String content;
  final int likes;
  final int commentCount;
  final bool isLikedByUser;
  final DateTime createdAt;

  CommunityPostModel({
    this.id,
    required this.authorName,
    this.authorAvatar,
    required this.category,
    required this.content,
    this.likes = 0,
    this.commentCount = 0,
    this.isLikedByUser = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: json['id'],
      authorName: json['authorName'] ?? 'Anonymous',
      authorAvatar: json['authorAvatar'],
      category: json['category'] ?? 'General',
      content: json['content'] ?? '',
      likes: json['likes'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      isLikedByUser: json['isLikedByUser'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'category': category,
      'content': content,
      'likes': likes,
      'commentCount': commentCount,
      'isLikedByUser': isLikedByUser,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  CommunityPostModel copyWith({
    int? id,
    String? authorName,
    String? authorAvatar,
    String? category,
    String? content,
    int? likes,
    int? commentCount,
    bool? isLikedByUser,
    DateTime? createdAt,
  }) {
    return CommunityPostModel(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      category: category ?? this.category,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
