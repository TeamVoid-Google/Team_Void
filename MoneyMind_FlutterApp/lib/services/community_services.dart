import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/community_models.dart';

class CommunityService {
  final String baseUrl;

  CommunityService({required this.baseUrl});

  // User endpoints
  Future<User> createUser(String username, String handle, {String? bio}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/community/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'handle': handle,
          'bio': bio,
        }),
      ).timeout(const Duration(seconds: 60)); // Increased timeout

      if (response.statusCode == 201) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create user: ${response.body}');
      }
    } catch (e) {
      print('Error in createUser: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<UserDetail> getUserDetails(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/community/users/$userId'),
      ).timeout(const Duration(seconds: 60)); // Increased timeout

      if (response.statusCode == 200) {
        return UserDetail.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get user details: ${response.body}');
      }
    } catch (e) {
      print('Error in getUserDetails: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<User> updateUser(int userId, {String? username, String? bio}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/community/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (username != null) 'username': username,
          if (bio != null) 'bio': bio,
        }),
      ).timeout(const Duration(seconds: 60)); // Increased timeout

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update user: ${response.body}');
      }
    } catch (e) {
      print('Error in updateUser: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<String> uploadProfileImage(int userId, File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/community/users/$userId/profile-image'),
      );

      final fileName = imageFile.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', fileExtension),
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 120)); // Extended timeout for uploads
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final filePath = data['file_path'];

        // Convert relative path to absolute URL if needed
        if (filePath.startsWith('/')) {
          return '$baseUrl$filePath';
        }
        return filePath;
      } else {
        throw Exception('Failed to upload profile image: ${response.body}');
      }
    } catch (e) {
      print('Error in uploadProfileImage: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<void> followUser(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/community/users/$userId/follow'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 204) {
        throw Exception('Failed to follow user: ${response.body}');
      }
    } catch (e) {
      print('Error in followUser: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<void> unfollowUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/community/users/$userId/follow'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 204) {
        throw Exception('Failed to unfollow user: ${response.body}');
      }
    } catch (e) {
      print('Error in unfollowUser: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<List<User>> getUserFollowers(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/community/users/$userId/followers'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((user) => User.fromJson(user)).toList();
      } else {
        throw Exception('Failed to get followers: ${response.body}');
      }
    } catch (e) {
      print('Error in getUserFollowers: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<List<User>> getUserFollowing(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/community/users/$userId/following'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((user) => User.fromJson(user)).toList();
      } else {
        throw Exception('Failed to get following: ${response.body}');
      }
    } catch (e) {
      print('Error in getUserFollowing: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<List<User>> searchUsers(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/community/users/search?query=$query'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((user) => User.fromJson(user)).toList();
      } else {
        throw Exception('Failed to search users: ${response.body}');
      }
    } catch (e) {
      print('Error in searchUsers: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Post> createPost(String content, {File? imageFile}) async {
    try {
      print('Creating post with content: $content');
      print('Image file: ${imageFile?.path}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/community/posts'),
      );

      request.fields['content'] = content;

      if (imageFile != null) {
        print('Attaching image file');
        final fileName = imageFile.path.split('/').last;
        final fileExtension = fileName.split('.').last.toLowerCase();

        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            contentType: MediaType('image', fileExtension),
          ),
        );
      }

      print('Sending request to: ${request.url}');
      final streamedResponse = await request.send().timeout(const Duration(seconds: 120)); // Extended timeout for uploads
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final postData = jsonDecode(response.body);

        // Fix image URL if it's a relative path
        if (postData['image_url'] != null && postData['image_url'].toString().startsWith('/')) {
          postData['image_url'] = '$baseUrl${postData['image_url']}';
        }

        final post = Post.fromJson(postData);
        print('Post created successfully with ID: ${post.id}');
        return post;
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create post: ${response.body}');
      }
    } catch (e) {
      print('Exception in createPost: $e');
      throw Exception('Error creating post: $e');
    }
  }

  Future<Post> getPost(int postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/community/posts/$postId'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final postData = jsonDecode(response.body);

        // Fix image URL if it's a relative path
        if (postData['image_url'] != null && postData['image_url'].toString().startsWith('/')) {
          postData['image_url'] = '$baseUrl${postData['image_url']}';
        }

        return Post.fromJson(postData);
      } else {
        throw Exception('Failed to get post: ${response.body}');
      }
    } catch (e) {
      print('Error in getPost: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<FeedResponse> getFeed({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/community/feed?page=$page'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final feedData = jsonDecode(response.body);

        // Fix image URLs in posts if they're relative paths
        if (feedData['posts'] != null) {
          for (var post in feedData['posts']) {
            if (post['image_url'] != null && post['image_url'].toString().startsWith('/')) {
              post['image_url'] = '$baseUrl${post['image_url']}';
            }
          }
        }

        return FeedResponse.fromJson(feedData);
      } else {
        throw Exception('Failed to get feed: ${response.body}');
      }
    } catch (e) {
      print('Error in getFeed: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<FeedResponse> getDiscoverFeed({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/community/discover?page=$page'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final feedData = jsonDecode(response.body);

        // Fix image URLs in posts if they're relative paths
        if (feedData['posts'] != null) {
          for (var post in feedData['posts']) {
            if (post['image_url'] != null && post['image_url'].toString().startsWith('/')) {
              post['image_url'] = '$baseUrl${post['image_url']}';
            }
          }
        }

        return FeedResponse.fromJson(feedData);
      } else {
        throw Exception('Failed to get discover feed: ${response.body}');
      }
    } catch (e) {
      print('Error in getDiscoverFeed: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<void> likePost(int postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/community/posts/$postId/like'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 204) {
        throw Exception('Failed to like post: ${response.body}');
      }
    } catch (e) {
      print('Error in likePost: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<void> unlikePost(int postId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/community/posts/$postId/like'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 204) {
        throw Exception('Failed to unlike post: ${response.body}');
      }
    } catch (e) {
      print('Error in unlikePost: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<void> bookmarkPost(int postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/community/posts/$postId/bookmark'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 204) {
        throw Exception('Failed to bookmark post: ${response.body}');
      }
    } catch (e) {
      print('Error in bookmarkPost: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<void> removeBookmark(int postId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/community/posts/$postId/bookmark'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 204) {
        throw Exception('Failed to remove bookmark: ${response.body}');
      }
    } catch (e) {
      print('Error in removeBookmark: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<FeedResponse> getBookmarkedPosts({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/community/bookmarks?page=$page'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final feedData = jsonDecode(response.body);

        // Fix image URLs in posts if they're relative paths
        if (feedData['posts'] != null) {
          for (var post in feedData['posts']) {
            if (post['image_url'] != null && post['image_url'].toString().startsWith('/')) {
              post['image_url'] = '$baseUrl${post['image_url']}';
            }
          }
        }

        return FeedResponse.fromJson(feedData);
      } else {
        throw Exception('Failed to get bookmarked posts: ${response.body}');
      }
    } catch (e) {
      print('Error in getBookmarkedPosts: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<List<Post>> getUserPosts(int userId, {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/community/users/$userId/posts?page=$page'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Fix image URLs in posts if they're relative paths
        for (var post in data) {
          if (post['image_url'] != null && post['image_url'].toString().startsWith('/')) {
            post['image_url'] = '$baseUrl${post['image_url']}';
          }
        }

        return data.map((post) => Post.fromJson(post)).toList();
      } else {
        throw Exception('Failed to get user posts: ${response.body}');
      }
    } catch (e) {
      print('Error in getUserPosts: $e');
      throw Exception('Network error: $e');
    }
  }

  // Comment endpoints
  Future<Comment> createComment(int postId, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/community/comments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'post_id': postId,
          'text': text,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 201) {
        return Comment.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create comment: ${response.body}');
      }
    } catch (e) {
      print('Error in createComment: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<List<Comment>> getPostComments(int postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/community/posts/$postId/comments'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((comment) => Comment.fromJson(comment)).toList();
      } else {
        throw Exception('Failed to get post comments: ${response.body}');
      }
    } catch (e) {
      print('Error in getPostComments: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<void> likeComment(int commentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/community/comments/$commentId/like'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 204) {
        throw Exception('Failed to like comment: ${response.body}');
      }
    } catch (e) {
      print('Error in likeComment: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<void> unlikeComment(int commentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/community/comments/$commentId/like'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 204) {
        throw Exception('Failed to unlike comment: ${response.body}');
      }
    } catch (e) {
      print('Error in unlikeComment: $e');
      throw Exception('Network error: $e');
    }
  }

  // Reply endpoints
  Future<Reply> createReply(int commentId, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/community/replies'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'comment_id': commentId,
          'text': text,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 201) {
        return Reply.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create reply: ${response.body}');
      }
    } catch (e) {
      print('Error in createReply: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<List<Reply>> getCommentReplies(int commentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/community/comments/$commentId/replies'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((reply) => Reply.fromJson(reply)).toList();
      } else {
        throw Exception('Failed to get comment replies: ${response.body}');
      }
    } catch (e) {
      print('Error in getCommentReplies: $e');
      throw Exception('Network error: $e');
    }
  }
}