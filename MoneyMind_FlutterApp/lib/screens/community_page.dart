import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../models/community_models.dart';
import '../services/community_services.dart';
import '../providers/user_provider.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute(
      builder: (context) => const CommunityPage(),
    );
  }

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

// Search user delegate for finding users in the community
class UserSearchDelegate extends SearchDelegate<String> {
  final CommunityService communityService;
  List<User> _searchResults = [];
  bool _isLoading = false;

  UserSearchDelegate({required this.communityService});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          _searchResults = [];
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) {
      _fetchResults(query);
    }
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isNotEmpty) {
      _fetchResults(query);
    }
    return _buildSearchResults(context);
  }

  // New method that doesn't use context unnecessarily
  Future<void> _fetchResults(String query) async {
    if (query.isEmpty || _isLoading) return;

    _isLoading = true;

    try {
      _searchResults = await communityService.searchUsers(query);
    } catch (e) {
      debugPrint('Error searching users: $e');
    } finally {
      _isLoading = false;
    }
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: query.isEmpty
            ? const Text('Start typing to search users')
            : const Text('No users found'),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.profileImage != null
                ? NetworkImage(user.profileImage!)
                : const AssetImage('assets/profile.png') as ImageProvider,
          ),
          title: Text(user.username),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.handle, style: const TextStyle(color: Colors.blue)),
              Text(
                user.bio ?? '',
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          trailing: TextButton(
            onPressed: () {
              // Follow user functionality
              communityService.followUser(user.id).catchError((e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error following user: $e')),
                );
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Follow'),
          ),
          onTap: () {
            // Navigate to user profile or show more details
            Navigator.pop(context, user.id.toString());
          },
        );
      },
    );
  }
}

class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CommunityService _communityService;
  late RefreshController _refreshController;
  late UserProvider _userProvider;

  // Track posts data
  List<Post> _posts = [];
  int? _nextPage;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;

  // Comment and post creation controllers
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();

  // Image picker for post creation
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshController = RefreshController(initialRefresh: false);

    // Load initial data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize service and provider
    _communityService = Provider.of<CommunityService>(context);
    _userProvider = Provider.of<UserProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    _commentController.dispose();
    _replyController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingInitial = true;
    });

    try {
      final feedResponse = await _communityService.getFeed();
      setState(() {
        _posts = feedResponse.posts;
        _nextPage = feedResponse.nextPage;
        _isLoadingInitial = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingInitial = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading posts: $e')),
      );
    }
  }

  Future<void> _loadMoreData() async {
    if (_nextPage == null || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final feedResponse = await _communityService.getFeed(page: _nextPage!);
      setState(() {
        _posts.addAll(feedResponse.posts);
        _nextPage = feedResponse.nextPage;
        _isLoadingMore = false;
      });
      _refreshController.loadComplete();
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      _refreshController.loadFailed();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading more posts: $e')),
      );
    }
  }

  Future<void> _refreshData() async {
    try {
      final feedResponse = await _communityService.getFeed();
      setState(() {
        _posts = feedResponse.posts;
        _nextPage = feedResponse.nextPage;
      });
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing posts: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _createPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;

    // Show loading
    setState(() {
      _isSubmitting = true;
    });

    try {
      final newPost = await _communityService.createPost(content, imageFile: _imageFile);
      setState(() {
        _posts.insert(0, newPost);
        _postController.clear();
        _imageFile = null;
        _isSubmitting = false;
      });
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
    }
  }

  void _showNewPostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'New Post',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                          _postController.clear();
                          _imageFile = null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: _userProvider.currentUser?.profileImage != null
                            ? NetworkImage(_userProvider.currentUser!.profileImage!)
                            : const AssetImage('assets/profile.png') as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _postController,
                          decoration: const InputDecoration(
                            hintText: 'Share something with the community...',
                            border: InputBorder.none,
                          ),
                          maxLines: 5,
                          minLines: 3,
                        ),
                      ),
                    ],
                  ),
                  if (_imageFile != null)
                    Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                _imageFile = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image, color: Colors.green),
                            onPressed: () {
                              _pickImage().then((_) {
                                setModalState(() {});
                              });
                            },
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _createPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text('Post'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleLikePost(int postIndex) async {
    final post = _posts[postIndex];
    final newIsLiked = !post.isLiked;
    final newLikesCount = post.likesCount + (newIsLiked ? 1 : -1);

    // Optimistic update
    setState(() {
      _posts[postIndex] = post.copyWith(
        isLiked: newIsLiked,
        likesCount: newLikesCount,
      );
    });

    try {
      if (newIsLiked) {
        await _communityService.likePost(post.id);
      } else {
        await _communityService.unlikePost(post.id);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _posts[postIndex] = post;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating like: $e')),
      );
    }
  }

  Future<void> _toggleBookmarkPost(int postIndex) async {
    final post = _posts[postIndex];
    final newIsBookmarked = !post.isBookmarked;

    // Optimistic update
    setState(() {
      _posts[postIndex] = post.copyWith(
        isBookmarked: newIsBookmarked,
      );
    });

    try {
      if (newIsBookmarked) {
        await _communityService.bookmarkPost(post.id);
      } else {
        await _communityService.removeBookmark(post.id);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _posts[postIndex] = post;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating bookmark: $e')),
      );
    }
  }

  Future<void> _addComment(int postIndex) async {
    final post = _posts[postIndex];
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    try {
      await _communityService.createComment(post.id, commentText);

      // Update post comment count
      setState(() {
        _posts[postIndex] = post.copyWith(
          commentsCount: post.commentsCount + 1,
        );
      });

      _commentController.clear();
      Navigator.pop(context);

      // Refresh the post to get updated comments
      _loadPostComments(post.id, postIndex);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: $e')),
      );
    }
  }

  Future<void> _loadPostComments(int postId, int postIndex) async {
    try {
      final comments = await _communityService.getPostComments(postId);

      // Show the comments in a bottom sheet
      _showCommentsBottomSheet(context, comments, postId, postIndex);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading comments: $e')),
      );
    }
  }

  void _showCommentsBottomSheet(
      BuildContext context,
      List<Comment> comments,
      int postId,
      int postIndex,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Comments (${comments.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return CommentWidget(
                            comment: comment,
                            onReply: (commentId) async {
                              final replyText = _replyController.text.trim();
                              if (replyText.isEmpty) return;

                              try {
                                await _communityService.createReply(commentId, replyText);

                                // Refresh comments to show the new reply
                                final updatedComments = await _communityService.getPostComments(postId);
                                setModalState(() {
                                  comments.clear();
                                  comments.addAll(updatedComments);
                                });

                                _replyController.clear();
                                Navigator.pop(context); // Close reply dialog
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error adding reply: $e')),
                                );
                              }
                            },
                            communityService: _communityService,
                            replyController: _replyController,
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                        left: 8,
                        right: 8,
                        top: 8,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: _userProvider.currentUser?.profileImage != null
                                ? NetworkImage(_userProvider.currentUser!.profileImage!)
                                : const AssetImage('assets/profile.png') as ImageProvider,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                hintText: 'Add a comment...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(20)),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.blue),
                            onPressed: () => _addComment(postIndex),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Community',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          // Search users button
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              showSearch(
                context: context,
                delegate: UserSearchDelegate(communityService: _communityService),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar for Following/For you
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Following'),
                Tab(text: 'For you'),
              ],
              onTap: (index) {
                // Load appropriate feed based on tab
                setState(() {
                  _isLoadingInitial = true;
                  _posts = [];
                });

                if (index == 0) {
                  // Following tab
                  _communityService.getFeed().then((response) {
                    setState(() {
                      _posts = response.posts;
                      _nextPage = response.nextPage;
                      _isLoadingInitial = false;
                    });
                  }).catchError((e) {
                    setState(() {
                      _isLoadingInitial = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error loading feed: $e')),
                    );
                  });
                } else {
                  // For you tab
                  _communityService.getDiscoverFeed().then((response) {
                    setState(() {
                      _posts = response.posts;
                      _nextPage = response.nextPage;
                      _isLoadingInitial = false;
                    });
                  }).catchError((e) {
                    setState(() {
                      _isLoadingInitial = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error loading discover feed: $e')),
                    );
                  });
                }
              },
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Following tab
                _buildPostsList(),

                // For you tab
                _buildPostsList(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewPostDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildPostsList() {
    if (_isLoadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return const Center(
        child: Text('No posts to show. Follow users to see their posts here!'),
      );
    }

    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: _nextPage != null,
      onRefresh: _refreshData,
      onLoading: _loadMoreData,
      header: const WaterDropHeader(),
      footer: CustomFooter(
        builder: (context, mode) {
          Widget body;
          if (mode == LoadStatus.idle) {
            body = const Text("Pull up to load more");
          } else if (mode == LoadStatus.loading) {
            body = const CircularProgressIndicator();
          } else if (mode == LoadStatus.failed) {
            body = const Text("Load failed! Click retry!");
          } else if (mode == LoadStatus.canLoading) {
            body = const Text("Release to load more");
          } else {
            body = const Text("No more data");
          }
          return SizedBox(
            height: 55.0,
            child: Center(child: body),
          );
        },
      ),
      child: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(_posts[index], index);
        },
      ),
    );
  }

  Widget _buildPostCard(Post post, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile image
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green,
                  backgroundImage: post.user.profileImage != null
                      ? NetworkImage(post.user.profileImage!)
                      : const AssetImage('assets/profile.png') as ImageProvider,
                ),
                const SizedBox(width: 10),
                // Username and handle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.user.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        post.user.handle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Time since post
                Text(
                  _getTimeAgo(post.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Post content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              post.content,
              style: const TextStyle(fontSize: 14),
            ),
          ),

          // Post image (if any)
          if (post.hasImage && post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  print('Image URL was: ${post.imageUrl}');
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 50,
                          color: Colors.grey),
                    ),
                  );
                },
              ),
            ),

          // Post actions
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Like button - toggles between outlined and filled
                IconButton(
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () => _toggleLikePost(index),
                ),
                // Share button
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.blue),
                  onPressed: () {
                    // Share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sharing post...')),
                    );
                  },
                ),
                // Comment button - opens comment dialog
                IconButton(
                  icon: const Icon(Icons.comment_outlined, color: Colors.green),
                  onPressed: () => _loadPostComments(post.id, index),
                ),
                // Bookmark button
                IconButton(
                  icon: Icon(
                    post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.orange,
                  ),
                  onPressed: () => _toggleBookmarkPost(index),
                ),
              ],
            ),
          ),

          // Display like count
          if (post.likesCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
              child: Text(
                '${post.likesCount} ${post.likesCount == 1 ? 'like' : 'likes'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
              ),
            ),

          // Display comment count
          if (post.commentsCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: GestureDetector(
                onTap: () => _loadPostComments(post.id, index),
                child: Text(
                  'View all ${post.commentsCount} ${post.commentsCount == 1 ? 'comment' : 'comments'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

class CommentWidget extends StatelessWidget {
  final Comment comment;
  final Function(int) onReply;
  final CommunityService communityService;
  final TextEditingController replyController;

  const CommentWidget({
    Key? key,
    required this.comment,
    required this.onReply,
    required this.communityService,
    required this.replyController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: comment.user.profileImage != null
                    ? NetworkImage(comment.user.profileImage!)
                    : const AssetImage('assets/profile.png') as ImageProvider,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.user.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          comment.user.handle,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Text(comment.text),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _getTimeAgo(comment.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _showReplyDialog(context),
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (comment.repliesCount > 0)
                          FutureBuilder<List<Reply>>(
                            future: communityService.getCommentReplies(comment.id),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                );
                              }
                              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                return GestureDetector(
                                  onTap: () => _showReplies(context, snapshot.data!),
                                  child: Text(
                                    'View ${comment.repliesCount} ${comment.repliesCount == 1 ? 'reply' : 'replies'}',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      comment.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                      size: 16,
                    ),
                    onPressed: () {
                      // Toggle like on comment
                      if (comment.isLiked) {
                        communityService.unlikeComment(comment.id);
                      } else {
                        communityService.likeComment(comment.id);
                      }
                    },
                  ),
                  if (comment.likesCount > 0)
                    Text(
                      '${comment.likesCount}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  void _showReplyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Reply to comment',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                      replyController.clear();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Show parent comment
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: comment.user.profileImage != null
                          ? NetworkImage(comment.user.profileImage!)
                          : const AssetImage('assets/profile.png') as ImageProvider,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comment.user.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                comment.user.handle,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(comment.text),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/profile.png'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: replyController,
                      decoration: const InputDecoration(
                        hintText: 'Write your reply',
                        border: InputBorder.none,
                      ),
                      maxLines: 5,
                      minLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onReply(comment.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Reply'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showReplies(BuildContext context, List<Reply> replies) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Replies to ${comment.user.username}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: replies.length,
                    itemBuilder: (context, index) {
                      final reply = replies[index];
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: reply.user.profileImage != null
                                      ? NetworkImage(reply.user.profileImage!)
                                      : const AssetImage('assets/profile.png') as ImageProvider,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            reply.user.username,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            reply.user.handle,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(reply.text),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getTimeAgo(reply.createdAt),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 8,
                    right: 8,
                    top: 8,
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundImage: AssetImage('assets/profile.png'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: replyController,
                          decoration: const InputDecoration(
                            hintText: 'Add a reply...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () {
                          Navigator.pop(context);
                          onReply(comment.id);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}