import 'package:flutter/material.dart';
import '../constants/neu_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'package:collection/collection.dart';
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final Map<DateTime, List<WorkoutEntry>> _workoutHistory = {};
  final Set<ExerciseTemplate> _exerciseTemplates = {};
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  // Controllers
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
    _loadExerciseTemplates();
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: "CALENDAR"),
              Tab(text: "EXERCISES"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCalendarView(),
                _buildExerciseView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2025, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            if (!selectedDay.isAfter(DateTime.now())) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          eventLoader: (day) {
            return _workoutHistory[DateTime(day.year, day.month, day.day)] ?? [];
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isNotEmpty) {
                return Positioned(
                  right: 1,
                  bottom: 1,
                  child: _buildEventMarker(events),
                );
              }
              return null;
            },
          ),
        ),
        Expanded(
          child: _buildWorkoutList(),
        ),
      ],
    );
  }

  Widget _buildExerciseView() {
    final exercisesByCategory = groupBy(
      _exerciseTemplates.toList(),
      (ExerciseTemplate e) => e.category,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: NeuConstants.neuBrutalismButtonStyle(
              color: NeuConstants.primaryColor,
            ),
            onPressed: () => _showAddExerciseDialog(context),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.black),
                SizedBox(width: 8),
                Text(
                  'ADD EXERCISE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: exercisesByCategory.isEmpty
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: NeuConstants.neuBrutalismBoxDecoration(
                      color: Colors.white,
                    ),
                    child: const Text(
                      'No exercises added yet\nTap the button above to add exercises',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: exercisesByCategory.length,
                  itemBuilder: (context, index) {
                    final category = exercisesByCategory.keys.elementAt(index);
                    final exercises = exercisesByCategory[category]!;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: NeuConstants.neuBrutalismBoxDecoration(
                        color: Colors.white,
                      ),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Text(
                              '${exercises.length} exercises',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        children: exercises.map((exercise) => ListTile(
                          title: Text(exercise.name),
                          subtitle: Text(exercise.notes ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditExerciseDialog(context, exercise),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _showDeleteExerciseDialog(context, exercise),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _showLogWorkoutDialog(context, exercise),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWorkoutList() {
    final selectedDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final workouts = _workoutHistory[selectedDate] ?? [];
    final isToday = isSameDay(selectedDate, today);

    if (selectedDate.isAfter(today)) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: NeuConstants.neuBrutalismBoxDecoration(
            color: Colors.white,
          ),
          child: const Text(
            'Cannot view or add workouts for future dates',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    if (workouts.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: NeuConstants.neuBrutalismBoxDecoration(
            color: Colors.white,
          ),
          child: Text(
            isToday 
                ? 'No workouts logged for today\nTap the button above to add exercises'
                : 'No workouts were logged for this day',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: NeuConstants.neuBrutalismBoxDecoration(
            color: Colors.white,
          ),
          child: ListTile(
            title: Text(
              workout.exercise,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${workout.sets} sets × ${workout.reps} reps @ ${workout.weight}kg',
            ),
            trailing: isToday
                ? IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        workouts.removeAt(index);
                        if (workouts.isEmpty) {
                          _workoutHistory.remove(_selectedDay);
                        }
                        _saveWorkoutData();
                      });
                    },
                  )
                : null,
          ),
        );
      },
    );
  }

  Future<void> _loadWorkoutData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? workoutJson = prefs.getString('workoutHistory');
    if (workoutJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(workoutJson);
      setState(() {
        _workoutHistory.clear();
        decoded.forEach((key, value) {
          final date = DateTime.parse(key);
          final workouts = (value as List)
              .map((w) => WorkoutEntry.fromJson(w))
              .toList();
          _workoutHistory[date] = workouts;
        });
      });
    }
  }

  Future<void> _saveWorkoutData() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutData = _workoutHistory.map(
      (key, value) => MapEntry(
        key.toIso8601String(),
        value.map((e) => e.toJson()).toList(),
      ),
    );
    await prefs.setString('workoutHistory', jsonEncode(workoutData));
  }

  Future<void> _loadExerciseTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('exerciseTemplates');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      setState(() {
        _exerciseTemplates.clear();
        _exerciseTemplates.addAll(
          decoded.map((e) => ExerciseTemplate.fromJson(e)),
        );
      });
    }
  }

  Future<void> _saveExerciseTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _exerciseTemplates.map((e) => e.toJson()).toList();
    await prefs.setString('exerciseTemplates', jsonEncode(data));
  }

  void _showAddExerciseDialog(BuildContext context) {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final notesController = TextEditingController();

    final existingCategories = _exerciseTemplates
        .map((e) => e.category)
        .toSet()
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Exercise'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'Enter exercise name',
                ),
              ),
              const SizedBox(height: 8),
              existingCategories.isEmpty
                  ? TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        hintText: 'Enter category (e.g., Chest, Back)',
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      hint: const Text('Select or type new category'),
                      items: [
                        ...existingCategories.map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'new_category',
                          child: Text('+ Add New Category'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == 'new_category') {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('New Category'),
                              content: TextField(
                                controller: categoryController,
                                decoration: const InputDecoration(
                                  labelText: 'Category Name',
                                  hintText: 'Enter new category name',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('CANCEL'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('ADD'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          categoryController.text = value ?? '';
                        }
                      },
                    ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Enter any additional notes',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && 
                  (categoryController.text.isNotEmpty || existingCategories.isNotEmpty)) {
                setState(() {
                  _exerciseTemplates.add(ExerciseTemplate(
                    name: nameController.text,
                    category: categoryController.text.isNotEmpty 
                        ? categoryController.text 
                        : existingCategories.first,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  ));
                  _saveExerciseTemplates();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showLogWorkoutDialog(BuildContext context, ExerciseTemplate exercise) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final selectedDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    if (!isSameDay(selectedDate, today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only log workouts for today'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _setsController.clear();
    _repsController.clear();
    _weightController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log ${exercise.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sets'),
            ),
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
            ),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              if (_setsController.text.isNotEmpty && _repsController.text.isNotEmpty) {
                setState(() {
                  final entry = WorkoutEntry(
                    exercise: exercise.name,
                    sets: int.parse(_setsController.text),
                    reps: int.parse(_repsController.text),
                    weight: double.tryParse(_weightController.text) ?? 0,
                    category: exercise.category,
                    date: selectedDate,
                  );
                  
                  if (_workoutHistory.containsKey(selectedDate)) {
                    _workoutHistory[selectedDate]!.add(entry);
                  } else {
                    _workoutHistory[selectedDate] = [entry];
                  }
                  _saveWorkoutData();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showEditExerciseDialog(BuildContext context, ExerciseTemplate exercise) {
    final nameController = TextEditingController(text: exercise.name);
    final categoryController = TextEditingController(text: exercise.category);
    final notesController = TextEditingController(text: exercise.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Exercise Name'),
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && categoryController.text.isNotEmpty) {
                setState(() {
                  _exerciseTemplates.remove(exercise);
                  _exerciseTemplates.add(ExerciseTemplate(
                    name: nameController.text,
                    category: categoryController.text,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  ));
                  _saveExerciseTemplates();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showDeleteExerciseDialog(BuildContext context, ExerciseTemplate exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text('Are you sure you want to delete "${exercise.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              setState(() {
                _exerciseTemplates.remove(exercise);
                _saveExerciseTemplates();
              });
              Navigator.pop(context);
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventMarker(List events) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: events.map((event) => const SizedBox.shrink()).toList(),
    );
  }
  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}

class WorkoutEntry {
  final String id;
  final String exercise;
  final int sets;
  final int reps;
  final double weight;
  final DateTime date;
  final String? category;

  WorkoutEntry({
    String? id,
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.weight,
    DateTime? date,
    this.category,
  }) : 
    this.id = id ?? DateTime.now().toIso8601String(),
    this.date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'exercise': exercise,
    'sets': sets,
    'reps': reps,
    'weight': weight,
    'date': date.toIso8601String(),
    'category': category,
  };

  factory WorkoutEntry.fromJson(Map<String, dynamic> json) => WorkoutEntry(
    id: json['id'],
    exercise: json['exercise'],
    sets: json['sets'],
    reps: json['reps'],
    weight: json['weight'].toDouble(),
    date: DateTime.parse(json['date']),
    category: json['category'],
  );
}

class ExerciseTemplate {
  final String name;
  final String category;
  final String? notes;

  ExerciseTemplate({
    required this.name,
    required this.category,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'notes': notes,
  };

  factory ExerciseTemplate.fromJson(Map<String, dynamic> json) => ExerciseTemplate(
    name: json['name'],
    category: json['category'],
    notes: json['notes'],
  );

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is ExerciseTemplate &&
    runtimeType == other.runtimeType &&
    name == other.name &&
    category == other.category;

  @override
  int get hashCode => name.hashCode ^ category.hashCode;
}