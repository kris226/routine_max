import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final double targetPercentage;
  final Function(bool) onThemeChanged;
  final Function(double) onTargetChanged;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.targetPercentage,
    required this.onThemeChanged,
    required this.onTargetChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _localTarget;

  @override
  void initState() {
    super.initState();
    _localTarget = widget.targetPercentage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "SETTINGS",
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, letterSpacing: 0.8),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Switch between light and dark theme"),
              value: widget.isDarkMode,
              activeColor: const Color(0xFF2563EB),
              onChanged: widget.onThemeChanged,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Daily Target", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("${_localTarget.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  ],
                ),
                const Text("Completion % needed to keep your streak", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Slider(
                  value: _localTarget,
                  min: 10,
                  max: 100,
                  divisions: 18,
                  activeColor: const Color(0xFF2563EB),
                  label: "${_localTarget.toInt()}%",
                  onChanged: (val) => setState(() => _localTarget = val),
                  onChangeEnd: (val) => widget.onTargetChanged(val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}