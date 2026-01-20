class Chapter {
  final int number;
  final String title;
  final int totalSlides;
  final bool isCompleted;

  Chapter({
    required this.number,
    required this.title,
    required this.totalSlides,
    this.isCompleted = false,
  });
}
