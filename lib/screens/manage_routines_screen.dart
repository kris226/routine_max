import 'package:flutter/material.dart';
import '../models/routine_preset.dart';
import 'edit_routine_screen.dart';

class ManageRoutinesScreen extends StatefulWidget {
  final List<RoutinePreset> presets;
  final Function(List<RoutinePreset>) onPresetsChanged;

  const ManageRoutinesScreen({
    super.key,
    required this.presets,
    required this.onPresetsChanged,
  });

  @override
  State<ManageRoutinesScreen> createState() => _ManageRoutinesScreenState();
}

class _ManageRoutinesScreenState extends State<ManageRoutinesScreen> {
  late List<RoutinePreset> _localPresets;

  @override
  void initState() {
    super.initState();
    _localPresets = List.from(widget.presets);
  }

  // --- CREATE NEW ROUTINE DIRECTLY IN EDIT SCREEN ---
  void _createNewPreset() {
    final newPreset = RoutinePreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'New Routine',
      activeDays: [],
      habits: [],
    );

    _localPresets.add(newPreset);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRoutineScreen(
          preset: newPreset,
          allPresets: _localPresets,
          onSave: (updatedPreset) {
            setState(() {});
            widget.onPresetsChanged(_localPresets);
          },
        ),
      ),
    );
  }

  // --- DELETE CONFIRMATION DIALOG ---
  void _confirmDeletePreset(int index) {
    final preset = _localPresets[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Routine?"),
        content: Text("Are you sure you want to delete '${preset.name}'? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _localPresets.removeAt(index);
              });
              widget.onPresetsChanged(_localPresets);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- OPEN FULL EDIT SCREEN ---
  void _openEditRoutineScreen(RoutinePreset preset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRoutineScreen(
          preset: preset,
          allPresets: _localPresets,
          onSave: (updatedPreset) {
            setState(() {});
            widget.onPresetsChanged(_localPresets);
          },
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
          "MANAGE ROUTINES",
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, letterSpacing: 0.8),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Create New Preset Routine",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: _createNewPreset,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _localPresets.length,
              itemBuilder: (context, presetIndex) {
                final preset = _localPresets[presetIndex];
                final activeHabitsCount = preset.habits.where((h) => !h.isGraduated).length;

                return Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.black.withOpacity(0.08)),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Assigned: ${preset.activeDays.length} days • $activeHabitsCount ${activeHabitsCount == 1 ? 'habit' : 'habits'}",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Color(0xFF2563EB)),
                              tooltip: "Edit Routine",
                              onPressed: () => _openEditRoutineScreen(preset),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              tooltip: "Delete Routine",
                              onPressed: () => _confirmDeletePreset(presetIndex),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}