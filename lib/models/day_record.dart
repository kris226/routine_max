import 'habit_item.dart';

class DayRecord {
  final DateTime date;
  final double completionPercentage;
  final List<HabitItem> habits;
  final String note;

  DayRecord({
    required this.date,
    required this.completionPercentage,
    required this.habits,
    this.note = '',
  });

  bool get isPerfect => completionPercentage >= 100.0;
  bool get isLazy => completionPercentage == 0.0;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'completionPercentage': completionPercentage,
        'habits': habits.map((h) => h.toJson()).toList(),
        'note': note,
      };

  factory DayRecord.fromJson(Map<String, dynamic> json) => DayRecord(
        date: DateTime.parse(json['date']),
        completionPercentage: (json['completionPercentage'] as num).toDouble(),
        habits: json['habits'] != null
            ? (json['habits'] as List).map((h) => HabitItem.fromJson(h)).toList()
            : [],
        note: json['note'] ?? '',
      );
}