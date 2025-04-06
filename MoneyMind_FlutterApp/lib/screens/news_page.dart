// lib/screens/news_page.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../models/news_article.dart';
import '../services/api_service.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute(
      builder: (context) => const NewsPage(),
    );
  }

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  String _selectedCategory = 'Trending';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final ApiService _apiService = ApiService();

  List<NewsArticle> _articles = [];
  List<NewsArticle> _featuredArticles = [];

  // Categories at the top with icons
  final List<Map<String, dynamic>> _categories = [
    {
      'icon': Icons.show_chart,
      'title': 'Market & Economy',
      'color': Colors.green.shade100,
      'iconColor': Colors.green,
    },
    {
      'icon': Icons.account_balance_wallet,
      'title': 'Personal Finance',
      'color': Colors.orange.shade100,
      'iconColor': Colors.orange,
    },
    {
      'icon': Icons.search,
      'title': 'Investment & Wealth',
      'color': Colors.blue.shade100,
      'iconColor': Colors.blue,
    },
    {
      'icon': Icons.handshake,
      'title': 'Business & Fintech',
      'color': Colors.pink.shade100,
      'iconColor': Colors.pink,
    },
    {
      'icon': Icons.menu_book,
      'title': 'Financial Education',
      'color': Colors.purple.shade100,
      'iconColor': Colors.purple,
    },
  ];

  // News tabs
  final List<String> _newsTabs = [
    'Trending', 'My Topics', 'Local News', 'Fact Check', 'Startups', 'Investments'
  ];

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      if (_selectedCategory == 'Trending') {
        final articles = await _apiService.getTrendingNews();
        setState(() {
          _articles = articles;
          _featuredArticles = articles.take(2).toList();
        });
      } else if (_selectedCategory == 'My Topics') {
        // Example user interests - in a real app, these would come from user preferences
        List<String> userInterests = ['finance', 'stocks', 'investment'];
        final articles = await _apiService.getPersonalizedNews(userInterests);
        setState(() {
          _articles = articles;
          _featuredArticles = articles.take(2).toList();
        });
      } else {
        final articles = await _apiService.getNewsByCategory(_selectedCategory);
        setState(() {
          _articles = articles;
          _featuredArticles = articles.take(2).toList();
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load news: $e';
      });
      print('Error fetching news: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
          'News',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? _buildErrorWidget()
          : RefreshIndicator(
        onRefresh: _fetchNews,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories with circular icons
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category['title'].toString().split(' ')[0];
                        });
                        _fetchNews();
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: category['color'],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                category['icon'],
                                color: category['iconColor'],
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 70,
                            child: Text(
                              category['title'].toString().split(' ')[0],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Personalized News title
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'Personalized News',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Featured news cards
            SizedBox(
              height: 180,
              child: _featuredArticles.isEmpty
                  ? const Center(child: Text('No featured news available'))
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _featuredArticles.length,
                itemBuilder: (context, index) {
                  final article = _featuredArticles[index];
                  return GestureDetector(
                    onTap: () {
                      _showArticleDetail(context, article);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                        image: DecorationImage(
                          image: article.urlToImage != null && article.urlToImage!.startsWith('http')
                              ? NetworkImage(article.urlToImage!) as ImageProvider
                              : AssetImage('assets/placeholder.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      article.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (article.source != null && article.source!['name'] != null)
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  article.source!['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // News category tabs
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _newsTabs.length,
                itemBuilder: (context, index) {
                  final tab = _newsTabs[index];
                  final isSelected = tab == _selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = tab;
                      });
                      _fetchNews();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // News list
            Expanded(
              child: _articles.isEmpty
                  ? const Center(child: Text('No news available for this category'))
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _articles.length,
                itemBuilder: (context, index) {
                  final article = _articles[index];
                  return GestureDetector(
                    onTap: () {
                      _showArticleDetail(context, article);
                    },
                    child: Container(
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                        image: DecorationImage(
                          image: article.urlToImage != null && article.urlToImage!.startsWith('http')
                              ? NetworkImage(article.urlToImage!) as ImageProvider
                              : AssetImage('assets/placeholder.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          article.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (article.source != null && article.source!['name'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              article.source!['name'],
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.8),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load news',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchNews,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String searchQuery = '';
        return AlertDialog(
          title: const Text('Search News'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter keywords...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              searchQuery = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (searchQuery.isNotEmpty) {
                  Navigator.of(context).pop();
                  setState(() {
                    _isLoading = true;
                  });
                  try {
                    final results = await _apiService.searchNews(searchQuery);
                    setState(() {
                      _articles = results;
                      _featuredArticles = results.take(2).toList();
                      _selectedCategory = 'Search';
                    });
                  } catch (e) {
                    setState(() {
                      _hasError = true;
                      _errorMessage = 'Error searching for news: $e';
                    });
                    print('Error searching news: $e');
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showArticleDetail(BuildContext context, NewsArticle article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Article image
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        image: DecorationImage(
                          image: article.urlToImage != null && article.urlToImage!.startsWith('http')
                              ? NetworkImage(article.urlToImage!) as ImageProvider
                              : AssetImage('assets/placeholder.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                          // Close button
                          Positioned(
                            top: 16,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white),
                              ),
                            ),
                          ),
                          // Source and date
                          if (article.source != null && article.source!['name'] != null)
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  article.source!['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Article content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (article.publishedAt != null)
                            Text(
                              _formatDate(article.publishedAt!),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            article.description ?? 'No description available',
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (article.url != null)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.link),
                              label: const Text('Read Full Article'),
                              onPressed: () {
                                // In a real app, use url_launcher package to open the URL
                                print('Opening URL: ${article.url}');
                              },
                            ),
                          const SizedBox(height: 20),
                          // Share and save buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  // Share functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Sharing article...')),
                                  );
                                },
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.bookmark_border),
                                label: const Text('Save'),
                                onPressed: () {
                                  // Save functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Article saved')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Related news section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[100],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Related News',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // This would normally be populated by a related news API call
                          // For now, showing 2 related articles from the same category
                          for (var i = 0; i < min(2, _articles.where((a) => a.category == article.category && a.title != article.title).length); i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  // Show the related article
                                  final relatedArticle = _articles.where((a) =>
                                  a.category == article.category &&
                                      a.title != article.title
                                  ).toList()[i];
                                  _showArticleDetail(context, relatedArticle);
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: _articles.where((a) =>
                                          a.category == article.category &&
                                              a.title != article.title
                                          ).toList()[i].urlToImage != null &&
                                              _articles.where((a) =>
                                              a.category == article.category &&
                                                  a.title != article.title
                                              ).toList()[i].urlToImage!.startsWith('http')
                                              ? NetworkImage(_articles.where((a) =>
                                          a.category == article.category &&
                                              a.title != article.title
                                          ).toList()[i].urlToImage!) as ImageProvider
                                              : AssetImage('assets/placeholder.jpg'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _articles.where((a) =>
                                            a.category == article.category &&
                                                a.title != article.title
                                            ).toList()[i].title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (_articles.where((a) =>
                                          a.category == article.category &&
                                              a.title != article.title
                                          ).toList()[i].source != null &&
                                              _articles.where((a) =>
                                              a.category == article.category &&
                                                  a.title != article.title
                                              ).toList()[i].source!['name'] != null)
                                            Text(
                                              _articles.where((a) =>
                                              a.category == article.category &&
                                                  a.title != article.title
                                              ).toList()[i].source!['name'],
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
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to format date
  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(date);

      if (difference.inDays > 7) {
        // Format as date if older than a week
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        // Format as days ago
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        // Format as hours ago
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else {
        // Format as minutes ago
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      }
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }
}