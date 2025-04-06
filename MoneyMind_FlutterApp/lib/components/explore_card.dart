// lib/components/explore_card.dart
import 'package:flutter/material.dart';
import '../screens/news_page.dart';
import '../screens/product_finder_page.dart';
import '../screens/community_page.dart';
import '../screens/profile_page.dart';

class ExploreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final Color backgroundColor;

  const ExploreCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
    this.backgroundColor = const Color(0xFFE8F3FF),
  }) : super(key: key);

  void _handleNavigation(BuildContext context) {
    switch (title.toLowerCase()) {
      case 'news':
        Navigator.of(context).push(NewsPage.route());
        break;
      case 'community':
        Navigator.of(context).push(CommunityPage.route());
        break;
      case 'product finder':
        Navigator.of(context).push(ProductFinderPage.route());
        break;
      case 'user profile':
        Navigator.of(context).push(ProfilePage.route());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleNavigation(context),
      child: Hero(
        tag: 'explore_card_$title',
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 45,
                  color: iconColor,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: iconColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}