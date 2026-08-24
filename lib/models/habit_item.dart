class HabitItem {
  final String id;
  String title;
  bool isCompleted;
  int importanceWeight; // 0 = Low (0x), 1 = Normal (1x), 2 = Core (2x)
  bool isSkill;
  String skillName;
  bool isGraduated;

  HabitItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.importanceWeight = 1,
    this.isSkill = false,
    this.skillName = '',
    this.isGraduated = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'importanceWeight': importanceWeight,
      'isSkill': isSkill,
      'skillName': skillName,
      'isGraduated': isGraduated,
    };
  }

  factory HabitItem.fromJson(Map<String, dynamic> json) {
    return HabitItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      importanceWeight: json['importanceWeight'] ?? 1,
      isSkill: json['isSkill'] ?? false,
      skillName: json['skillName'] ?? '',
      isGraduated: json['isGraduated'] ?? false,
    );
  }
}

/// Shared weighted-completion calculation. Use this everywhere completion
/// % is computed so Daily Routine, main.dart, and history never disagree.
double calculateWeightedCompletion(List<HabitItem> habits) {
  if (habits.isEmpty) return 0.0;

  int totalPossiblePoints = 0;
  int earnedPoints = 0;

  for (var h in habits) {
    totalPossiblePoints += h.importanceWeight;
    if (h.isCompleted) earnedPoints += h.importanceWeight;
  }

  if (totalPossiblePoints == 0) {
    final completedCount = habits.where((h) => h.isCompleted).length;
    return (completedCount / habits.length) * 100;
  }

  return (earnedPoints / totalPossiblePoints) * 100;
}