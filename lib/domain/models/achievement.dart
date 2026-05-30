class Achievement {
  final String id;
  final String name;
  final String emoji;
  final String description;
  bool unlocked;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    this.unlocked = false,
    this.unlockedAt,
  });
}
