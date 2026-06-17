// lib/models/community_comment_model.dart

class CommunityCommentModel {
  final int? id;
  final int postId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final DateTime createdAt;

  // Threaded reply parsing properties
  final int? parentId;
  final String cleanContent;

  CommunityCommentModel({
    this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       parentId = _parseParentId(content),
       cleanContent = _parseCleanContent(content);

  static int? _parseParentId(String text) {
    final match = RegExp(r'^\[reply:(\d+)\]').firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  static String _parseCleanContent(String text) {
    final match = RegExp(r'^\[reply:\d+\](.*)$', dotAll: true).firstMatch(text);
    if (match != null) {
      return match.group(1)!;
    }
    return text;
  }

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) {
    return CommunityCommentModel(
      id: json['id'],
      postId: json['post_id'],
      authorId: json['author_id'],
      authorName: json['author_name'] ?? 'Anonymous',
      authorAvatar: json['author_avatar'],
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'post_id': postId,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ParsedComment {
  final CommunityCommentModel comment;
  final List<ParsedComment> replies = [];

  ParsedComment({
    required this.comment,
  });
}

List<ParsedComment> buildCommentTree(List<Map<String, dynamic>> rawComments) {
  // Replace loop with functional JSON mapping
  final commentMap = Map.fromEntries(
    rawComments
        .map((data) => CommunityCommentModel.fromJson(data))
        .where((comment) => comment.id != null)
        .map((comment) => MapEntry(comment.id!, ParsedComment(comment: comment))),
  );

  // Link replies to their parents
  for (final parsed in commentMap.values) {
    final parentId = parsed.comment.parentId;
    if (parentId != null && commentMap.containsKey(parentId)) {
      commentMap[parentId]!.replies.add(parsed);
    }
  }

  // Filter and return only root comments functionally
  return commentMap.values.where((parsed) {
    final parentId = parsed.comment.parentId;
    return parentId == null || !commentMap.containsKey(parentId);
  }).toList();
}
