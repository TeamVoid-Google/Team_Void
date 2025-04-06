import 'package:flutter/material.dart';

class NewsCard {
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final IconData icon;


  NewsCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    required this.icon,

  });
}

class NewsCardSlider extends StatefulWidget {
  final List<NewsCard> cards;

  const NewsCardSlider({
    Key? key,
    required this.cards,
  }) : super(key: key);

  @override
  State<NewsCardSlider> createState() => _NewsCardSliderState();
}

class _NewsCardSliderState extends State<NewsCardSlider> {
  late final PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.9,
      initialPage: 0,
    );
    _pageController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _currentPage = _pageController.page ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500, // Adjust based on your needs
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.cards.length,
        itemBuilder: (context, index) {
          final card = widget.cards[index];
          final double difference = (index - _currentPage);
          final double scale = 1 - (difference.abs() * 0.1).clamp(0.0, 0.4);
          final double opacity = 1 - (difference.abs() * 0.3).clamp(0.0, 1.0);

          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: NewsCardItem(card: card),
            ),
          );
        },
      ),
    );
  }
}

class NewsCardItem extends StatelessWidget {
  final NewsCard card;

  const NewsCardItem({
    Key? key,
    required this.card,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(card.icon, color: Colors.white, size: 24),
                const Icon(Icons.arrow_outward, color: Colors.white70),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(card.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    card.subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  card.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}