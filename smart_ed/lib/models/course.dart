import 'package:flutter/material.dart';
import 'chapter.dart';

class Course {
  final String name;
  final int totalChapters;
  final double progress;
  final Color color;
  final List<Chapter> chapters;

  Course({
    required this.name,
    required this.totalChapters,
    required this.progress,
    required this.color,
    required this.chapters,
  });

  int get totalSlides {
    return chapters.fold(0, (sum, chapter) => sum + chapter.totalSlides);
  }
}
