import 'habit_item.dart';

class RoutinePreset {
  String id;
  String name;
  List<HabitItem> habits;
  List<int> activeDays;

  RoutinePreset({
    required this.id,
    required this.name,
    required this.habits,
    required this.activeDays,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'habits': habits.map((h) => h.toJson()).toList(),
        'activeDays': activeDays,
      };

  factory RoutinePreset.fromJson(Map<String, dynamic> json) => RoutinePreset(
        id: json['id'],
        name: json['name'],
        habits: (json['habits'] as List).map((h) => HabitItem.fromJson(h)).toList(),
        activeDays: List<int>.from(json['activeDays']),
      );
}