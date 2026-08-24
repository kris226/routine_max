import 'package:flutter/material.dart';
import '../models/routine_preset.dart';
import '../models/habit_item.dart';

class EditRoutineScreen extends StatefulWidget {
  final RoutinePreset preset;
  final List<RoutinePreset> allPresets;
  final Function(RoutinePreset) onSave;

  const EditRoutineScreen({
    super.key,
    required this.preset,
    required this.allPresets,
    required this.onSave,
  });

  @override
  State<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends State<EditRoutineScreen> {
  late TextEditingController _nameController;
  late List<int> _selectedDays;
  late List<HabitItem> _habits;

  final daysOfWeek = [
    {'id': 1, 'label': 'M'},
    {'id': 2, 'label': 'T'},
    {'id': 3, 'label': 'W'},
    {'id': 4, 'label': 'T'},
    {'id': 5, 'label': 'F'},
    {'id': 6, 'label': 'S'},
    {'id': 7, 'label': 'S'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset.name);
    _selectedDays = List.from(widget.preset.activeDays);
    _habits = List.from(widget.preset.habits);
  }

  bool _isDayTakenByOther(int day) {
    for (var other in widget.allPresets) {
      if (other.id != widget.preset.id && other.activeDays.contains(day)) {
        return true;
      }
    }
    return false;
  }

  void _showHabitDialog({HabitItem? habit, int? index}) {
    final titleController = TextEditingController(text: habit?.title ?? '');
    final skillNameController = TextEditingController(text: habit?.skillName ?? '');
    int importance = habit?.importanceWeight ?? 1;
    bool isSkill = habit?.isSkill ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              habit == null ? "Add Habit" : "Edit Habit",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Habit Title",
                      hintText: "e.g. Practice handstand 10 mins",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Importance Weight:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildWeightChip(0, "LOW 0x", importance, (val) => setModalState(() => importance = val)),
                      const SizedBox(width: 8),
                      _buildWeightChip(1, "NORMAL 1x", importance, (val) => setModalState(() => importance = val)),
                      const SizedBox(width: 8),
                      _buildWeightChip(2, "CORE 2x", importance, (val) => setModalState(() => importance = val)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text("Track as Skill 🏆", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    value: isSkill,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setModalState(() => isSkill = val),
                  ),
                  if (isSkill) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: skillNameController,
                      decoration: const InputDecoration(
                        labelText: "Skill Name",
                        hintText: "e.g. Muscle Up",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                onPressed: () {
                  final text = titleController.text.trim();
                  if (text.isEmpty) return;
                  final skillText = skillNameController.text.trim();

                  setState(() {
                    if (index == null) {
                      _habits.add(HabitItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: text,
                        importanceWeight: importance,
                        isSkill: isSkill,
                        skillName: isSkill ? skillText : '',
                      ));
                    } else {
                      _habits[index].title = text;
                      _habits[index].importanceWeight = importance;
                      _habits[index].isSkill = isSkill;
                      _habits[index].skillName = isSkill ? skillText : '';
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text("Save", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeightChip(int value, String label, int current, Function(int) onSelect) {
    final isSelected = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("EDIT ROUTINE", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF2563EB), size: 28),
            onPressed: () {
              widget.preset.name = _nameController.text.trim();
              widget.preset.activeDays = _selectedDays;
              widget.preset.habits = _habits;
              widget.onSave(widget.preset);
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Routine Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Text("Active Days:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: daysOfWeek.map((day) {
                final dayId = day['id'] as int;
                final isSelected = _selectedDays.contains(dayId);
                final isTaken = _isDayTakenByOther(dayId);

                Color bgColor;
                Color textColor;

                if (isSelected) {
                  bgColor = const Color(0xFF2563EB);
                  textColor = Colors.white;
                } else if (isTaken) {
                  bgColor = Colors.grey.shade300;
                  textColor = Colors.grey.shade600;
                } else {
                  bgColor = Colors.grey.shade100;
                  textColor = Colors.black87;
                }

                return GestureDetector(
                  onTap: () {
                    if (isTaken) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("This day is already assigned to another routine."),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      if (isSelected) {
                        _selectedDays.remove(dayId);
                      } else {
                        _selectedDays.add(dayId);
                      }
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      day['label'] as String,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Habits", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _showHabitDialog(),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text("Add Habit", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _habits.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _habits.removeAt(oldIndex);
                  _habits.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final h = _habits[index];
                return Card(
                  key: ValueKey(h.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(h.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showHabitDialog(habit: h, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            final removedHabit = h;
                            final removedIndex = index;
                            setState(() => _habits.removeAt(index));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Deleted '${removedHabit.title}'"),
                                action: SnackBarAction(
                                  label: "Undo",
                                  onPressed: () {
                                    setState(() => _habits.insert(removedIndex, removedHabit));
                                  },
                                ),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}