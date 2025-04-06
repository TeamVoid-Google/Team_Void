// lib/utils/constants.dart
import 'package:flutter/material.dart';
import '../models/project_card.dart';

class NewsData {
  static final List<ProjectCard> newsCards = [
    ProjectCard(
      title: 'THE LINE',
      subtitle: 'Invest in NEOM',
      imagePath: 'assets/the_line.jpg',
      description: 'A cognitive city stretching across 170 kilometers...',

    ),
    ProjectCard(
      title: 'MAGNA COASTAL',
      subtitle: 'Invest in Future',
      imagePath: 'assets/magna.jpg',
      description: 'An undiscovered coastal jewel...',

    ),
    // Add more cards here
  ];
}