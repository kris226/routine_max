import 'package:flutter/material.dart';
import '../models/day_record.dart';
import '../models/routine_preset.dart';
import '../models/habit_item.dart';
import '../utils/streak_utils.dart';
import '../widgets/animated_progress_bar.dart';
import '../theme/app_theme.dart';

class AccountScreen extends StatefulWidget {
  final Map<DateTime, DayRecord> history;
  final List<RoutinePreset> presets;
  final Function(List<RoutinePreset>)? onPresetsChanged;
  final double targetPercentage;

  const AccountScreen({
    super.key,
    required this.history,
    required this.presets,
    this.onPresetsChanged,
    this.targetPercentage = 80.0,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _selectedTab = 0; // 0 = Overview, 1 = Analytics

  int get _totalHabitsCompleted {
    int total = 0;
    for (var record in widget.history.values) {
      if (record.completionPercentage >= 0) {
        total += record.habits.where((h) => h.isCompleted).length;
      }
    }
    return total;
  }

  int get _totalPerfectDays {
    return widget.history.values.where((r) => r.completionPercentage >= 100).length;
  }

  int get _currentStreak =>
      StreakUtils.currentStreak(widget.history, (r) => r.completionPercentage >= widget.targetPercentage);

  int get _bestStreak =>
      StreakUtils.bestStreak(widget.history, (r) => r.completionPercentage >= widget.targetPercentage);

  double get _lifetimeConsistencyRate {
    final activeDays = widget.history.values.where((r) => r.completionPercentage >= 0).toList();
    if (activeDays.isEmpty) return 0.0;
    final totalPercentage = activeDays.fold(0.0, (sum, r) => sum + r.completionPercentage);
    return totalPercentage / activeDays.length;
  }

  int get _totalXP => (_totalHabitsCompleted * 10) + (_totalPerfectDays * 50);
  int get _userLevel => (_totalXP / 200).floor() + 1;
  double get _levelProgress => (_totalXP % 200) / 200;

  List<HabitItem> get _unlockedSkills {
    final List<HabitItem> skills = [];
    for (var preset in widget.presets) {
      for (var habit in preset.habits) {
        if (habit.isSkill && habit.isGraduated) {
          skills.add(habit);
        }
      }
    }
    return skills;
  }

  // --- SKILL VAULT ACTIONS ---
  void _renameSkill(HabitItem habit) {
    final controller = TextEditingController(text: habit.skillName.isNotEmpty ? habit.skillName : habit.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Rename Skill"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Skill Name", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              setState(() {
                habit.skillName = newName;
              });
              widget.onPresetsChanged?.call(widget.presets);
              Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteSkill(HabitItem habit) {
    final displayName = habit.skillName.isNotEmpty ? habit.skillName : habit.title;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Trophy?"),
        content: Text("'$displayName' and its habit will be permanently removed. This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                for (var preset in widget.presets) {
                  preset.habits.removeWhere((h) => h.id == habit.id);
                }
              });
              widget.onPresetsChanged?.call(widget.presets);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- ANALYTICS TAB COMPUTATIONS ---
  List<Map<String, dynamic>> get _habitMatrix {
    final Map<String, int> timesCompleted = {};
    final Map<String, int> timesScheduled = {};
    final Map<String, int> currentStreaks = {};
    final Map<String, int> maxStreaks = {};
    final Map<String, int> tempStreaks = {};

    final sortedDates = widget.history.keys.toList()..sort();

    for (var date in sortedDates) {
      final record = widget.history[date];
      if (record == null || record.completionPercentage < 0) continue;

      for (var h in record.habits) {
        timesScheduled[h.title] = (timesScheduled[h.title] ?? 0) + 1;
        if (h.isCompleted) {
          timesCompleted[h.title] = (timesCompleted[h.title] ?? 0) + 1;
          tempStreaks[h.title] = (tempStreaks[h.title] ?? 0) + 1;
          currentStreaks[h.title] = tempStreaks[h.title]!;
          if (tempStreaks[h.title]! > (maxStreaks[h.title] ?? 0)) {
            maxStreaks[h.title] = tempStreaks[h.title]!;
          }
        } else {
          tempStreaks[h.title] = 0;
          currentStreaks[h.title] = 0;
        }
      }
    }

    final List<Map<String, dynamic>> matrix = [];
    timesScheduled.forEach((title, total) {
      final done = timesCompleted[title] ?? 0;
      final rate = total > 0 ? (done / total) * 100 : 0.0;
      matrix.add({
        'title': title,
        'rate': rate,
        'currentStreak': currentStreaks[title] ?? 0,
        'bestStreak': maxStreaks[title] ?? 0,
      });
    });

    matrix.sort((a, b) => (b['rate'] as double).compareTo(a['rate'] as double));
    return matrix;
  }

  Map<int, double> get _dayOfWeekAverages {
    final Map<int, List<double>> dayScores = {1: [], 2: [], 3: [], 4: [], 5: [], 6: [], 7: []};

    for (var date in widget.history.keys) {
      final record = widget.history[date];
      if (record != null && record.completionPercentage >= 0) {
        dayScores[date.weekday]?.add(record.completionPercentage);
      }
    }

    final Map<int, double> averages = {};
    dayScores.forEach((weekday, scores) {
      if (scores.isEmpty) {
        averages[weekday] = 0.0;
      } else {
        averages[weekday] = scores.reduce((a, b) => a + b) / scores.length;
      }
    });

    return averages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: Text(
          "PROFILE & STATS",
          style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w900, letterSpacing: 0.8),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.isDark(context) ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTabOption(0, "Overview"),
                  _buildTabOption(1, "Analytics & Insights"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedTab == 0) _buildOverviewTab() else _buildAnalyticsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabOption(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.cardColor(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected ? const Color(0xFF2563EB) : AppTheme.textSecondary(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final unlocked = _unlockedSkills;
    final consistency = _lifetimeConsistencyRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.cardBorder(context)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                    child: const Icon(Icons.person_rounded, size: 36, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Athlete", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(12)),
                              child: Text("LVL $_userLevel", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text("Total XP: $_totalXP", style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Next Level Progress", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary(context))),
                      Text("${(_levelProgress * 100).toInt()}%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedProgressBar(
                    progress: _levelProgress,
                    height: 8,
                    activeColor: const Color(0xFF2563EB),
                    backgroundColor: Colors.grey.shade200,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildStatCard("Current Streak", "$_currentStreak d", Icons.local_fire_department_rounded, Colors.orange),
            const SizedBox(width: 12),
            _buildStatCard("Best Streak", "$_bestStreak d", Icons.emoji_events_rounded, Colors.amber),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard("Habits Done", "$_totalHabitsCompleted", Icons.check_circle_rounded, Colors.blue),
            const SizedBox(width: 12),
            _buildStatCard("Perfect Days", "$_totalPerfectDays", Icons.bolt_rounded, Colors.purple),
            const SizedBox(width: 12),
            _buildStatCard("Consistency", "${consistency.toInt()}%", Icons.show_chart_rounded, Colors.green),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Skill Vault", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
            Text("${unlocked.length} Unlocked", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 12),
        if (unlocked.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              border: Border.all(color: AppTheme.cardBorder(context)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.workspace_premium_rounded, size: 36, color: Colors.amber),
                ),
                const SizedBox(height: 12),
                Text("Vault is Empty", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                const SizedBox(height: 4),
                Text("Tag habits as skills, then mark them as learned to unlock trophies here!", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.4)),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: unlocked.length,
            itemBuilder: (context, index) {
              final skill = unlocked[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  border: Border.all(color: AppTheme.cardBorder(context)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 30),
                        const SizedBox(height: 6),
                        Text(skill.skillName.isNotEmpty ? skill.skillName : skill.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary(context))),
                        const SizedBox(height: 2),
                        const Text("UNLOCKED 🏆", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                      ],
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey, size: 18),
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'rename') _renameSkill(skill);
                          if (value == 'delete') _deleteSkill(skill);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'rename', child: Text("✏️ Rename")),
                          const PopupMenuItem(value: 'delete', child: Text("🗑️ Delete")),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    final matrix = _habitMatrix;
    final dayAverages = _dayOfWeekAverages;
    final dayLabels = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            border: Border.all(color: AppTheme.cardBorder(context)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Weekly Day-by-Day Heatmap", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
              const SizedBox(height: 4),
              Text("Average completion rates by day of the week", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final dayId = index + 1;
                  final avg = dayAverages[dayId] ?? 0.0;
                  final heightFactor = (avg / 100).clamp(0.05, 1.0);
                  Color barColor = const Color(0xFF2563EB);
                  if (avg < 50) barColor = Colors.orange;
                  if (avg == 0) barColor = Colors.grey.shade300;

                  return Column(
                    children: [
                      Text("${avg.toInt()}%", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary(context))),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        height: 100 * heightFactor,
                        width: 16,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(dayLabels[dayId]!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text("Habit Consistency Matrix", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
        const SizedBox(height: 12),
        if (matrix.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text("Complete habits over a few days to view matrix stats!", style: TextStyle(color: Colors.grey, fontSize: 13))),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matrix.length,
            itemBuilder: (context, index) {
              final item = matrix[index];
              final rate = item['rate'] as double;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  border: Border.all(color: AppTheme.cardBorder(context)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary(context))),
                        Text("${rate.toInt()}% Overall", style: TextStyle(fontWeight: FontWeight.bold, color: rate >= 80 ? const Color(0xFF2563EB) : Colors.orange, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedProgressBar(
                      progress: rate / 100,
                      height: 6,
                      activeColor: rate >= 80 ? const Color(0xFF2563EB) : Colors.orange,
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text("Active: ${item['currentStreak']}d 🔥", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary(context))),
                        const SizedBox(width: 16),
                        Text("Best: ${item['bestStreak']}d 🏆", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary(context))),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          border: Border.all(color: AppTheme.cardBorder(context)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context))),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}