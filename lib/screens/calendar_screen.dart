import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/day_record.dart';
import '../utils/streak_utils.dart';

class CalendarScreen extends StatefulWidget {
  final Map<DateTime, DayRecord> history;

  const CalendarScreen({super.key, required this.history});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();

  // --- 1. ACTIVE STREAK (At least 1 task done / >0%) ---
 int get _activeStreak =>
      StreakUtils.currentStreak(widget.history, (r) => r.completionPercentage > 0);


  // --- 2. PERFECT STREAK (100% completed) ---
 int get _perfectStreak =>
      StreakUtils.currentStreak(widget.history, (r) => r.completionPercentage >= 100);

  // Helper method to check if a DateTime represents today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Color _getDayColor(double percentage, DateTime date) {
    if (percentage < 0) return Colors.grey.shade300;       // Rest Day / Neutral
    if (percentage >= 80) return const Color(0xFF2563EB);  // Blue (Target Hit / 80%+)
    if (percentage >= 50) return const Color(0xFF10B981);  // Green (50% - 79%)
    if (percentage > 0) return const Color(0xFFF97316);   // Orange (1% - 49%)
    
    // 0% Logic: Neutral Slate Grey for today, Red for past days
    if (_isToday(date)) {
      return const Color(0xFF64748B);
    }
    return Colors.red.shade400;
  }

  void _showDayDetailsModal(BuildContext context, DateTime selectedDate, DayRecord? record) {
    final dateFormatted = "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        if (record == null) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(dateFormatted, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Icon(Icons.history_toggle_off, size: 36, color: Colors.grey),
                const SizedBox(height: 8),
                const Text("No routine recorded for this date.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final isNeutral = record.completionPercentage < 0;
        final completedCount = record.habits.where((h) => h.isCompleted).length;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dateFormatted, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getDayColor(record.completionPercentage, selectedDate).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isNeutral ? "Rest Day" : "${record.completionPercentage.toInt()}% Score",
                          style: TextStyle(
                            color: _getDayColor(record.completionPercentage, selectedDate),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isNeutral ? "No habits scheduled." : "$completedCount of ${record.habits.length} completed",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const Divider(height: 24),
                  if (!isNeutral)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: record.habits.length,
                      itemBuilder: (context, index) {
                        final habit = record.habits[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                habit.isCompleted ? Icons.check_circle : Icons.cancel,
                                color: habit.isCompleted ? Colors.green : Colors.redAccent,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(habit.title, style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                        );
                      },
                    ),
                  if (record.note.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text("Daily Note:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(record.note, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStreakBox({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String countText,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              countText,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day, {required bool isToday}) {
    final cleanDate = DateTime.utc(day.year, day.month, day.day);
    final record = widget.history[cleanDate];

    if (record != null) {
      return Center(
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _getDayColor(record.completionPercentage, cleanDate),
            shape: BoxShape.circle,
            border: isToday ? Border.all(color: Colors.black, width: 2) : null,
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade100,
          border: isToday ? Border.all(color: Colors.black, width: 1.5) : null,
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
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
        title: const Text(
          "HISTORY & STREAKS",
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, letterSpacing: 0.8),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            // --- TOP STREAK CARDS ---
            Row(
              children: [
                _buildStreakBox(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: Colors.orange,
                  title: "Active Streak",
                  countText: "$_activeStreak Days",
                  subtitle: "At least 1 task done",
                ),
                const SizedBox(width: 12),
                _buildStreakBox(
                  icon: Icons.bolt_rounded,
                  iconColor: Colors.blue,
                  title: "Perfect Streak",
                  countText: "$_perfectStreak Days",
                  subtitle: "100% completed",
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- CALENDAR CARD ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                startingDayOfWeek: StartingDayOfWeek.sunday,
                firstDay: DateTime.utc(2025, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                onDaySelected: (selectedDay, focusedDay) {
                  final cleanDate = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
                  final record = widget.history[cleanDate];

                  setState(() {
                    _focusedDay = focusedDay;
                  });

                  _showDayDetailsModal(context, cleanDate, record);
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) => _buildCalendarCell(day, isToday: false),
                  todayBuilder: (context, day, focusedDay) => _buildCalendarCell(day, isToday: true),
                  outsideBuilder: (context, day, focusedDay) => Center(
                    child: Text('${day.day}', style: TextStyle(color: Colors.grey.shade300)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}