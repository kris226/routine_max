import 'package:flutter/material.dart';
import 'models/routine_preset.dart';
import 'models/habit_item.dart';
import 'models/day_record.dart';
import 'services/storage_service.dart';
import 'screens/daily_routine_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/account_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RoutineMaxApp());
}

class RoutineMaxApp extends StatelessWidget {
  const RoutineMaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoutineMax',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int _selectedIndex = 2;
  bool _isLoading = true;
  DateTime _lastCheckedDate = DateTime.now();
  late PageController _pageController;

  List<RoutinePreset> _presets = [
    RoutinePreset(
      id: '1',
      name: 'Daily Grind',
      activeDays: [1, 2, 3, 4, 5, 6, 7],
      habits: [
        HabitItem(id: '1', title: "Muscle Ups - 10 mins"),
        HabitItem(id: '2', title: "Math practice - 10 mins"),
        HabitItem(id: '3', title: "Read 10 pages"),
        HabitItem(id: '4', title: "Cold shower"),
      ],
    ),
  ];

  Map<DateTime, DayRecord> _history = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addObserver(this);
    _loadAllData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndHandleRollover();
    }
  }

  void _checkAndHandleRollover() {
    final now = DateTime.now();
    final isNewDay = now.day != _lastCheckedDate.day ||
        now.month != _lastCheckedDate.month ||
        now.year != _lastCheckedDate.year;

    if (isNewDay) {
      _lastCheckedDate = now;
      _performDailyRollover();
    }
  }

  void _performDailyRollover() {
    for (var preset in _presets) {
      for (var habit in preset.habits) {
        habit.isCompleted = false;
      }
    }
    StorageService.savePresets(_presets);
    StorageService.saveLastCheckedDate(_lastCheckedDate);
    setState(() {});
  }

  Future<void> _loadAllData() async {
    final savedPresets = await StorageService.loadPresets();
    final savedHistory = await StorageService.loadHistory();
    final savedLastChecked = await StorageService.loadLastCheckedDate();

    List<RoutinePreset> activePresets = (savedPresets != null && savedPresets.isNotEmpty)
        ? savedPresets
        : _presets;

    Map<DateTime, DayRecord> activeHistory = savedHistory;

    final now = DateTime.now();
    final isNewDay = savedLastChecked == null ||
        savedLastChecked.day != now.day ||
        savedLastChecked.month != now.month ||
        savedLastChecked.year != now.year;

    if (isNewDay) {
      for (var preset in activePresets) {
        for (var habit in preset.habits) {
          habit.isCompleted = false;
        }
      }
      await StorageService.savePresets(activePresets);
    }

    _lastCheckedDate = now;
    await StorageService.saveLastCheckedDate(now);

    setState(() {
      _presets = activePresets;
      _history = activeHistory;
      _isLoading = false;
    });
  }

  void _updatePresets(List<RoutinePreset> updated) {
    setState(() {
      _presets = updated;
    });
    StorageService.savePresets(_presets);

    final now = DateTime.now();
    final todayWeekday = now.weekday;
    RoutinePreset? todayPreset;

    try {
      todayPreset = _presets.firstWhere((p) => p.activeDays.contains(todayWeekday));
    } catch (_) {
      todayPreset = null;
    }

    if (todayPreset == null) {
      _updateTodayCompletion(-1.0);
    } else {
      final activeHabits = todayPreset.habits.where((h) => !h.isGraduated).toList();
      _updateTodayCompletion(calculateWeightedCompletion(activeHabits));
    }
  }

  void _updateTodayCompletion(double percentage) {
    final now = DateTime.now();
    final todayClean = DateTime.utc(now.year, now.month, now.day);

    final todayWeekday = now.weekday;
    RoutinePreset? todayPreset;
    try {
      todayPreset = _presets.firstWhere((p) => p.activeDays.contains(todayWeekday));
    } catch (_) {
      todayPreset = null;
    }

    final activeHabits = todayPreset?.habits.where((h) => !h.isGraduated).toList() ?? [];
    final safePercentage = (todayPreset == null || activeHabits.isEmpty) ? -1.0 : percentage;

    final habitSnapshots = activeHabits
        .map((h) => HabitItem(
              id: h.id,
              title: h.title,
              isCompleted: h.isCompleted,
              isSkill: h.isSkill,
              skillName: h.skillName,
              isGraduated: h.isGraduated,
              importanceWeight: h.importanceWeight,
            ))
        .toList();

    final existingNote = _history[todayClean]?.note ?? '';

    setState(() {
      _history[todayClean] = DayRecord(
        date: todayClean,
        completionPercentage: safePercentage,
        habits: habitSnapshots,
        note: existingNote,
      );
    });

    StorageService.saveHistory(_history);
    StorageService.savePresets(_presets);
  }

  void _updateTodayNote(String note) {
    final now = DateTime.now();
    final todayClean = DateTime.utc(now.year, now.month, now.day);

    final existingRecord = _history[todayClean];

    setState(() {
      _history[todayClean] = DayRecord(
        date: todayClean,
        completionPercentage: existingRecord?.completionPercentage ?? -1.0,
        habits: existingRecord?.habits ?? [],
        note: note,
      );
    });

    StorageService.saveHistory(_history);
  }

  // --- REST DAY ---
  bool get _todayHasRoutine {
    final todayWeekday = DateTime.now().weekday;
    return _presets.any((p) => p.activeDays.contains(todayWeekday));
  }

  bool get _isRestDayToday {
    final now = DateTime.now();
    final todayClean = DateTime.utc(now.year, now.month, now.day);
    return _todayHasRoutine && (_history[todayClean]?.completionPercentage == -1.0);
  }

  void _setRestDay(bool isRest) {
    final now = DateTime.now();
    final todayClean = DateTime.utc(now.year, now.month, now.day);
    final existingNote = _history[todayClean]?.note ?? '';

    if (isRest) {
      setState(() {
        _history[todayClean] = DayRecord(
          date: todayClean,
          completionPercentage: -1.0,
          habits: [],
          note: existingNote,
        );
      });
      StorageService.saveHistory(_history);
    } else {
      final todayWeekday = now.weekday;
      RoutinePreset? todayPreset;
      try {
        todayPreset = _presets.firstWhere((p) => p.activeDays.contains(todayWeekday));
      } catch (_) {
        todayPreset = null;
      }
      final activeHabits = todayPreset?.habits.where((h) => !h.isGraduated).toList() ?? [];
      _updateTodayCompletion(calculateWeightedCompletion(activeHabits));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }

    final List<Widget> screens = [
      AccountScreen(history: _history, presets: _presets),
      CalendarScreen(history: _history),
      DailyRoutineScreen(
        presets: _presets,
        history: _history,
        onPresetsChanged: _updatePresets,
        onCompletionChanged: _updateTodayCompletion,
        onNoteSaved: _updateTodayNote,
        isRestDayToday: _isRestDayToday,
        onRestDayToggled: _setRestDay,
      ),
      const Center(child: Text("5-Person Group Feed\n(Coming Soon)")),
      const Center(child: Text("Settings & App Setup\n(Coming Soon)")),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: screens,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(index: 0, icon: Icons.person_rounded, label: 'Account'),
              _buildNavItem(index: 1, icon: Icons.calendar_month_rounded, label: 'Calendar'),
              _buildNavItem(index: 2, icon: Icons.check_circle_rounded, label: 'Routine', iconSize: 32),
              _buildNavItem(index: 3, icon: Icons.group_rounded, label: 'Group'),
              _buildNavItem(index: 4, icon: Icons.settings_rounded, label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    double iconSize = 24,
  }) {
    final isSelected = _selectedIndex == index;
    const activeColor = Color(0xFF2563EB);
    final inactiveColor = Colors.grey.shade400;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? activeColor : inactiveColor,
            size: iconSize,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}