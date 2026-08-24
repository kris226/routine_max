import 'package:flutter/material.dart';
import '../models/day_record.dart';
import '../models/routine_preset.dart';
import '../models/habit_item.dart';
import '../utils/streak_utils.dart';
import '../widgets/animated_progress_bar.dart';

class AccountScreen extends StatefulWidget {
  final Map<DateTime, DayRecord> history;
  final List<RoutinePreset> presets;

  const AccountScreen({
    super.key,
    required this.history,
    required this.presets,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _selectedTab = 0; // 0 = Overview, 1 = Analytics

  // --- GENERAL STATS CALCULATIONS ---

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
      StreakUtils.currentStreak(widget.history, (r) => r.completionPercentage >= 80);

   int get _bestStreak =>
      StreakUtils.bestStreak(widget.history, (r) => r.completionPercentage >= 80);

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "PROFILE & STATS",
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, letterSpacing: 0.8),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tab Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
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
            color: isSelected ? Colors.white : Colors.transparent,
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
              color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  // --- OVERVIEW TAB ---
  Widget _buildOverviewTab() {
    final unlocked = _unlockedSkills;
    final consistency = _lifetimeConsistencyRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level Profile Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
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
                            const Text("Athlete", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(12)),
                              child: Text("LVL $_userLevel", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text("Total XP: $_totalXP", style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
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
                      Text("Next Level Progress", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
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

        // Grid Metrics
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

        // Skill Vault
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Skill Vault", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            Text("${unlocked.length} Unlocked", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 12),
        if (unlocked.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.workspace_premium_rounded, size: 36, color: Colors.amber),
                ),
                const SizedBox(height: 12),
                const Text("Vault is Empty", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade300, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 30),
                    const SizedBox(height: 6),
                    Text(skill.skillName.isNotEmpty ? skill.skillName : skill.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    const Text("UNLOCKED 🏆", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // --- ANALYTICS TAB ---
  Widget _buildAnalyticsTab() {
    final matrix = _habitMatrix;
    final dayAverages = _dayOfWeekAverages;
    final dayLabels = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heatmap
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Weekly Day-by-Day Heatmap", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
                      Text("${avg.toInt()}%", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
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
                      Text(dayLabels[dayId]!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Habit Matrix Breakdown
        const Text("Habit Consistency Matrix", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
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
                        Text("Active: ${item['currentStreak']}d 🔥", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                        const SizedBox(width: 16),
                        Text("Best: ${item['bestStreak']}d 🏆", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
