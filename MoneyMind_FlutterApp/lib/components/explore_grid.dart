// lib/components/explore_grid.dart
import 'package:flutter/material.dart';
import 'explore_card.dart';

class ExploreGrid extends StatelessWidget {
  const ExploreGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      physics: const BouncingScrollPhysics(),
      children: [
        ExploreCard(
          icon: Icons.newspaper,
          title: 'News',
          description: 'Get personalized news for yourself.',
          iconColor: const Color.fromARGB(255, 255, 192, 5),
          backgroundColor: const Color.fromARGB(255, 255, 247, 230),
        ),
        ExploreCard(
          icon: Icons.people,
          title: 'Community',
          description: 'Connect with others.',
          iconColor: const Color.fromARGB(255, 90, 191, 121),
          backgroundColor: const Color.fromARGB(255, 236, 255, 241),
        ),
        ExploreCard(
          icon: Icons.search,
          title: 'Product Finder',
          description: 'Search for products based on your needs.',
          iconColor: const Color.fromARGB(255, 66, 133, 244),
          backgroundColor: const Color.fromARGB(255, 235, 242, 255),
        ),
        ExploreCard(
          icon: Icons.person,
          title: 'User profile',
          description: 'Learn more about your investment and track.',
          iconColor: const Color.fromARGB(255, 239, 68, 54),
          backgroundColor: const Color.fromARGB(255, 255, 235, 233),
        ),
      ],
    );
  }
}

// To make the grid more responsive, you might want to add this extension
extension on ExploreGrid {
  static Map<String, Map<String, dynamic>> cardData = {
    'News': {
      'icon': Icons.newspaper,
      'description': 'Get personalized news for yourself.',
      'iconColor': const Color.fromARGB(255, 255, 192, 5),
      'backgroundColor': const Color.fromARGB(255, 255, 247, 230),
    },
    'Investments': {
      'icon': Icons.trending_up,
      'description': 'Types of investment learn about them here.',
      'iconColor': const Color.fromARGB(255, 90, 191, 121),
      'backgroundColor': const Color.fromARGB(255, 236, 255, 241),
    },
    'Product Finder': {
      'icon': Icons.search,
      'description': 'Search for products based on your needs.',
      'iconColor': const Color.fromARGB(255, 66, 133, 244),
      'backgroundColor': const Color.fromARGB(255, 235, 242, 255),
    },
    'User profile': {
      'icon': Icons.person,
      'description': 'Learn more about your investment and track your portfolio.',
      'iconColor': const Color.fromARGB(255, 239, 68, 54),
      'backgroundColor': const Color.fromARGB(255, 255, 235, 233),
    },
  };
}