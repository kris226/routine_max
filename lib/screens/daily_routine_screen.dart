import 'package:flutter/material.dart';
import '../models/routine_preset.dart';
import '../models/habit_item.dart';
import '../models/day_record.dart';
import 'manage_routines_screen.dart';

class DailyRoutineScreen extends StatefulWidget {
  final List<RoutinePreset> presets;
  final Map<DateTime, DayRecord> history;
  final Function(List<RoutinePreset>) onPresetsChanged;
  final Function(double)? onCompletionChanged;
  final Function(String)? onNoteSaved;
  final bool isRestDayToday;
  final Function(bool)? onRestDayToggled;

  const DailyRoutineScreen({
    super.key,
    required this.presets,
    required this.history,
    required this.onPresetsChanged,
    this.onCompletionChanged,
    this.onNoteSaved,
    this.isRestDayToday = false,
    this.onRestDayToggled,
  });

  @override
  State<DailyRoutineScreen> createState() => _DailyRoutineScreenState();
}

class _DailyRoutineScreenState extends State<DailyRoutineScreen> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final todayClean = DateTime.utc(now.year, now.month, now.day);
    _noteController = TextEditingController(text: widget.history[todayClean]?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  RoutinePreset? get _todayRoutine {
    final currentDay = DateTime.now().weekday;
    try {
      return widget.presets.firstWhere(
        (preset) => preset.activeDays.contains(currentDay),
      );
    } catch (_) {
      return null;
    }
  }

  List<HabitItem> get _activeHabits {
    final routine = _todayRoutine;
    if (routine == null) return [];
    return routine.habits.where((h) => !h.isGraduated).toList();
  }

  double get _weightedCompletionPercentage {
    if (_todayRoutine == null) return 0.0;
    return calculateWeightedCompletion(_activeHabits);
  }

  Color _getScoreColor(double score) {
    if (score >= 80.0) return const Color(0xFF2563EB);
    if (score >= 50.0) return const Color(0xFF10B981);
    if (score > 0.0) return const Color(0xFFF97316);
    return const Color(0xFF64748B);
  }

  void _toggleHabit(HabitItem habit) {
    setState(() {
      habit.isCompleted = !habit.isCompleted;
    });

    widget.onPresetsChanged(widget.presets);

    if (widget.onCompletionChanged != null) {
      widget.onCompletionChanged!(_weightedCompletionPercentage);
    }
  }

  void _markSkillAsLearned(HabitItem habit) {
    final displayName = habit.skillName.isNotEmpty ? habit.skillName : habit.title;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Mark Skill as Learned?"),
        content: Text("'$displayName' will move to your trophy case and leave your daily tasks."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
            onPressed: () {
              setState(() {
                habit.isGraduated = true;
              });
              widget.onPresetsChanged(widget.presets);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("🏆 $displayName learned! Check your trophy case.")),
              );
            },
            child: const Text("Yes, I Learned It!", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _saveNote() {
    widget.onNoteSaved?.call(_noteController.text.trim());
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Note saved.")),
    );
  }

  void _confirmRestDay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Take a Rest Day?"),
        content: const Text("Today won't count toward your streaks, but it won't break them either."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B)),
            onPressed: () {
              widget.onRestDayToggled?.call(true);
              Navigator.pop(context);
            },
            child: const Text("Yes, Rest Today", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayRoutine = _todayRoutine;
    final habits = _activeHabits;
    final score = _weightedCompletionPercentage;
    final isTargetMet = score >= 80;
    final cardColor = _getScoreColor(score);
    final isResting = widget.isRestDayToday;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "DAILY ROUTINE",
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, letterSpacing: 0.8),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageRoutinesScreen(
                      presets: widget.presets,
                      onPresetsChanged: widget.onPresetsChanged,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 4),
                    Text("Manage", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isResting)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64748B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text("😴", style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      const Text(
                        "Resting Today",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Your streak is safe.",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onPressed: () => widget.onRestDayToggled?.call(false),
                        child: const Text("End Rest Day", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: cardColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                todayRoutine?.name ?? "No Routine Set Today",
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isTargetMet ? "Target Hit! (80%+ Goal)" : "Target: 80% to keep streak",
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                              ),
                            ],
                          ),
                          Text(
                            "${score.toInt()}%",
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 10,
                          width: double.infinity,
                          color: Colors.white.withOpacity(0.3),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final progress = (score / 100).clamp(0.0, 1.0);
                              return Stack(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeOutCubic,
                                    width: constraints.maxWidth * progress,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (todayRoutine != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _confirmRestDay,
                      icon: const Icon(Icons.bedtime_outlined, size: 16, color: Color(0xFF64748B)),
                      label: const Text("Take a Rest Day", style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ),
                  ),
                const SizedBox(height: 12),
                const Text("Today's Tasks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                if (todayRoutine == null || habits.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text("No tasks scheduled for today!", style: TextStyle(color: Colors.grey))),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200, width: 1.0),
                        ),
                        child: ListTile(
                          onTap: () => _toggleHabit(habit),
                          leading: Checkbox(
                            activeColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            value: habit.isCompleted,
                            onChanged: (_) => _toggleHabit(habit),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  habit.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    decoration: habit.isCompleted ? TextDecoration.lineThrough : null,
                                    color: habit.isCompleted ? Colors.grey : Colors.black87,
                                  ),
                                ),
                              ),
                              if (habit.importanceWeight == 2)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                  child: const Text("CORE 2x", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                )
                              else if (habit.importanceWeight == 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                                  child: const Text("LOW 0x", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                ),
                              if (habit.isSkill) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    habit.skillName.isNotEmpty ? "→ ${habit.skillName}" : "SKILL 🏆",
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: habit.isSkill
                              ? IconButton(
                                  icon: const Icon(Icons.emoji_events_outlined, color: Colors.amber),
                                  tooltip: "Mark as Learned",
                                  onPressed: () => _markSkillAsLearned(habit),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
              ],
              const SizedBox(height: 24),
              const Text("Daily Note", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: "How did today go?",
                        border: InputBorder.none,
                      ),
                    ),
                    TextButton(
                      onPressed: _saveNote,
                      child: const Text("Save Note", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}