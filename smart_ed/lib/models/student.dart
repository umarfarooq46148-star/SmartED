class Student {
  final String name;
  final String rollNumber;
  final String className;
  final String? profileImage;

  Student({
    required this.name,
    required this.rollNumber,
    required this.className,
    this.profileImage,
  });
}
