import 'package:flutter/material.dart';

void main() {
  runApp(const RoutineMaxApp());
}

class RoutineMaxApp extends StatelessWidget {
  const RoutineMaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoutineMax',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF6366F1),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          surface: Color(0xFF1E293B),
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DailyRoutineScreen(),
    const GroupFeedPlaceholderScreen(),
    const ProfilePlaceholderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: const Color(0xFF6366F1).withOpacity(0.3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle, color: Color(0xFF6366F1)),
            label: 'Routine',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group, color: Color(0xFF6366F1)),
            label: 'Group',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF6366F1)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HabitItem {
  String title;
  bool isCompleted;

  HabitItem({required this.title, this.isCompleted = false});
}

class DailyRoutineScreen extends StatefulWidget {
  const DailyRoutineScreen({super.key});

  @override
  State<DailyRoutineScreen> createState() => _DailyRoutineScreenState();
}

class _DailyRoutineScreenState extends State<DailyRoutineScreen> {
  final List<HabitItem> _habits = [
    HabitItem(title: "Muscle Ups - 10 mins"),
    HabitItem(title: "Math practice - 10 mins"),
    HabitItem(title: "Read 10 pages"),
    HabitItem(title: "Cold shower"),
  ];

  final TextEditingController _noteController = TextEditingController();

  double get _completionPercentage {
    if (_habits.isEmpty) return 0.0;
    int completed = _habits.where((h) => h.isCompleted).length;
    return (completed / _habits.length) * 100;
  }

  bool get _isPerfectDay => _habits.isNotEmpty && _completionPercentage == 100.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ROUTINEMAX',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isPerfectDay
                      ? const Color(0xFF059669)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isPerfectDay
                        ? const Color(0xFF10B981)
                        : Colors.white12,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _isPerfectDay ? "PERFECT DAY!" : "TODAY'S SCORE",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _isPerfectDay ? Colors.white : Colors.grey[400],
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${_completionPercentage.round()}%",
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    if (_isPerfectDay)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "🔥 Perfect Day Streak Secured!",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Daily Tasks",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF6366F1)),
                    onPressed: _showAddTaskDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _habits.length,
                  itemBuilder: (context, index) {
                    final habit = _habits[index];
                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          value: habit.isCompleted,
                          activeColor: const Color(0xFF6366F1),
                          onChanged: (bool? value) {
                            setState(() {
                              habit.isCompleted = value ?? false;
                            });
                          },
                        ),
                        title: Text(
                          habit.title,
                          style: TextStyle(
                            decoration: habit.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: habit.isCompleted
                                ? Colors.grey
                                : Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: "Daily note: How did today's execution feel?",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    TextEditingController taskController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text("Add New Habit"),
          content: TextField(
            controller: taskController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "e.g., Read 15 mins",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              onPressed: () {
                if (taskController.text.trim().isNotEmpty) {
                  setState(() {
                    _habits.add(HabitItem(title: taskController.text.trim()));
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Add", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class GroupFeedPlaceholderScreen extends StatelessWidget {
  const GroupFeedPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "5-Person Group Feed\n(Coming Soon)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}

class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "User Profile & History\n(Coming Soon)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}