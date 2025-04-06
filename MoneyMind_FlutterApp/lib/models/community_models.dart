class User {
  final int id;
  final String username;
  final String handle;
  final String? bio;
  final String? profileImage;

  User({
    required this.id,
    required this.username,
    required this.handle,
    this.bio,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      handle: json['handle'],
      bio: json['bio'],
      profileImage: json['profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'handle': handle,
      'bio': bio,
      'profile_image': profileImage,
    };
  }
}

class UserDetail extends User {
  final int followersCount;
  final int followingCount;
  final int postsCount;

  UserDetail({
    required int id,
    required String username,
    required String handle,
    String? bio,
    String? profileImage,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
  }) : super(
          id: id,
          username: username,
          handle: handle,
          bio: bio,
          profileImage: profileImage,
        );

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    return UserDetail(
      id: json['id'],
      username: json['username'],
      handle: json['handle'],
      bio: json['bio'],
      profileImage: json['profile_image'],
      followersCount: json['followers_count'],
      followingCount: json['following_count'],
      postsCount: json['posts_count'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({
      'followers_count': followersCount,
      'following_count': followingCount,
      'posts_count': postsCount,
    });
    return baseJson;
  }
}

class Post {
  final int id;
  final int userId;
  final User user;
  final String content;
  final bool hasImage;
  final String? imageUrl;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isBookmarked;

  Post({
    required this.id,
    required this.userId,
    required this.user,
    required this.content,
    required this.hasImage,
    this.imageUrl,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.isBookmarked,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['user_id'],
      user: User.fromJson(json['user']),
      content: json['content'],
      hasImage: json['has_image'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      likesCount: json['likes_count'],
      commentsCount: json['comments_count'],
      isLiked: json['is_liked'],
      isBookmarked: json['is_bookmarked'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user': user.toJson(),
      'content': content,
      'has_image': hasImage,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
      'is_bookmarked': isBookmarked,
    };
  }

  // Create a copy of this post with updated properties
  Post copyWith({
    int? likesCount,
    bool? isLiked,
    bool? isBookmarked,
    int? commentsCount,
  }) {
    return Post(
      id: id,
      userId: userId,
      user: user,
      content: content,
      hasImage: hasImage,
      imageUrl: imageUrl,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

class Comment {
  final int id;
  final int postId;
  final int userId;
  final User user;
  final String text;
  final DateTime createdAt;
  final int likesCount;
  final int repliesCount;
  final bool isLiked;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.user,
    required this.text,
    required this.createdAt,
    required this.likesCount,
    required this.repliesCount,
    required this.isLiked,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      user: User.fromJson(json['user']),
      text: json['text'],
      createdAt: DateTime.parse(json['created_at']),
      likesCount: json['likes_count'],
      repliesCount: json['replies_count'],
      isLiked: json['is_liked'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'user': user.toJson(),
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'likes_count': likesCount,
      'replies_count': repliesCount,
      'is_liked': isLiked,
    };
  }

  // Create a copy of this comment with updated properties
  Comment copyWith({
    int? likesCount,
    bool? isLiked,
    int? repliesCount,
  }) {
    return Comment(
      id: id,
      postId: postId,
      userId: userId,
      user: user,
      text: text,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

class Reply {
  final int id;
  final int commentId;
  final int userId;
  final User user;
  final String text;
  final DateTime createdAt;

  Reply({
    required this.id,
    required this.commentId,
    required this.userId,
    required this.user,
    required this.text,
    required this.createdAt,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      id: json['id'],
      commentId: json['comment_id'],
      userId: json['user_id'],
      user: User.fromJson(json['user']),
      text: json['text'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comment_id': commentId,
      'user_id': userId,
      'user': user.toJson(),
      'text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class FeedResponse {
  final List<Post> posts;
  final int? nextPage;

  FeedResponse({
    required this.posts,
    this.nextPage,
  });

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    return FeedResponse(
      posts: (json['posts'] as List<dynamic>)
          .map((post) => Post.fromJson(post))
          .toList(),
      nextPage: json['next_page'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'posts': posts.map((post) => post.toJson()).toList(),
      'next_page': nextPage,
    };
  }
}