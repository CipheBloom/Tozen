import 'package:flutter/material.dart';
import '../constants/neu_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

enum TaskType {
  exercise,
  diet,
  custom, // Added custom task type
}

class PlanTask {
  final String title;
  final TaskType type;

  PlanTask({
    required this.title,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type.toString().split('.').last,
    };
  }

  factory PlanTask.fromJson(Map<String, dynamic> json) {
    return PlanTask(
      title: json['title'],
      type: TaskType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => TaskType.exercise,
      ),
    );
  }
}

class ScheduledTask extends PlanTask {
  final DateTime time;

  ScheduledTask({
    required String title,
    required TaskType type,
    required this.time,
  }) : super(title: title, type: type);

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['time'] = time.toIso8601String();
    return json;
  }

  factory ScheduledTask.fromJson(Map<String, dynamic> json) {
    return ScheduledTask(
      title: json['title'],
      type: TaskType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => TaskType.exercise,
      ),
      time: DateTime.parse(json['time']),
    );
  }
}

class WorkoutPlan {
  final String title;
  final String duration;
  final String description;
  final String difficulty;
  final Color color;
  final IconData icon;
  final Map<String, List<ScheduledTask>> scheduledTasks;

  static const _iconMapping = {
    59635: Icons.fitness_center,
    // Add more IconData mappings as needed
  };

  WorkoutPlan({
    required this.title,
    required this.duration,
    required this.description,
    required this.difficulty,
    required this.color,
    required this.icon,
    required this.scheduledTasks,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'duration': duration,
      'description': description,
      'difficulty': difficulty,
      'color': color.value,
      'icon': icon.codePoint,
      'scheduledTasks': scheduledTasks.map((key, value) => MapEntry(
            key,
            value.map((task) => task.toJson()).toList(),
          )),
    };
  }

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      title: json['title'],
      duration: json['duration'],
      description: json['description'],
      difficulty: json['difficulty'],
      color: Color(json['color']),
      icon:
          _iconMapping[json['icon']] ?? Icons.fitness_center, // Use the mapping
      scheduledTasks: (json['scheduledTasks'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List).map((task) => ScheduledTask.fromJson(task)).toList(),
        ),
      ),
    );
  }
}

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  List<WorkoutPlan> _plans = [];
  final TextEditingController _taskController = TextEditingController();
  TimeOfDay selectedTime = TimeOfDay.now();
  int _recursionDepth = 0;
  String _difficultyLevel = 'Easy'; // Initial difficulty level

  void _recursiveFunction() {
    if (_recursionDepth > 100) {
      throw Exception('Recursion depth limit exceeded');
    }
    _recursionDepth++;
    // Recursive logic here
    _recursiveFunction();
    _recursionDepth--;
  }

  void _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime)
      setState(() {
        selectedTime = picked;
      });
  }

  void _changeDifficulty(String newDifficulty) {
    setState(() {
      _difficultyLevel = newDifficulty; // Update the difficulty level
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final plansJson = prefs.getStringList('workout_plans') ?? [];

    if (plansJson.isEmpty) {
      _plans = [];
      await _savePlans();
    } else {
      setState(() {
        _plans = plansJson
            .map((plan) => WorkoutPlan.fromJson(jsonDecode(plan)))
            .toList();
      });
    }
  }

  Future<void> _savePlans() async {
    final prefs = await SharedPreferences.getInstance();
    final plansJson = _plans.map((plan) => jsonEncode(plan.toJson())).toList();
    await prefs.setStringList('workout_plans', plansJson);
  }

  void _showPlanDetails(BuildContext context, WorkoutPlan plan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Plan Details'),
          content: SingleChildScrollView(
            // Wrap the Column in a SingleChildScrollView
            child: Column(
              mainAxisSize: MainAxisSize
                  .min, // Ensure the column takes only the necessary height
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: NeuConstants.neuBrutalismBoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duration: ${plan.duration}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Difficulty: ${plan.difficulty}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(plan.description),
                      const SizedBox(height: 24),
                      const Text(
                        'Weekly Schedule',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...plan.scheduledTasks.entries
                          .map((entry) => _buildDayScheduler(
                                context,
                                entry.key,
                                entry.value,
                                (tasks) {
                                  setState(() {
                                    plan.scheduledTasks[entry.key] = tasks;
                                  });
                                  _savePlans();
                                },
                              )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayScheduler(
    BuildContext context,
    String day,
    List<ScheduledTask> tasks,
    Function(List<ScheduledTask>) onTasksUpdated,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(day),
        children: [
          ListTile(
            title: const Text('Add Task'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTask(context, day, tasks, onTasksUpdated),
            ),
          ),
          if (tasks.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  leading: Icon(
                    task.type == TaskType.diet
                        ? Icons.restaurant
                        : Icons.fitness_center,
                  ),
                  title: Text(task.title),
                  subtitle: Text(
                    '${DateFormat.jm().format(task.time)} - ${task.type.name.toUpperCase()}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        tasks.removeAt(index);
                        onTasksUpdated(tasks);
                      });
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _addToTodoList(BuildContext context, WorkoutPlan plan) async {
    final today = DateTime.now();
    final dayName = _getDayName(today.weekday);

    if (plan.scheduledTasks.containsKey(dayName)) {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = today.toIso8601String().split('T')[0];
      final existingTasksJson = prefs.getStringList('tasks_$todayStr') ?? [];

      final existingTasks =
          existingTasksJson.map((task) => jsonDecode(task)).toList();

      for (final task in plan.scheduledTasks[dayName]!) {
        existingTasks.add({
          'title': task.title,
          'isCompleted': false,
        });
      }

      await prefs.setStringList(
        'tasks_$todayStr',
        existingTasks.map((task) => jsonEncode(task)).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tasks added to today\'s list!'),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tasks scheduled for today'),
          ),
        );
      }
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  void _startPlan(BuildContext context, WorkoutPlan plan) async {
    final today = DateTime.now();
    final dayName = _getDayName(today.weekday);
    final prefs = await SharedPreferences.getInstance();

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        title: Container(
          padding: const EdgeInsets.all(8),
          decoration: NeuConstants.neuBrutalismBoxDecoration(
            color: plan.color,
            offsetX: 2,
            offsetY: 2,
          ),
          child: Row(
            children: [
              Icon(plan.icon),
              const SizedBox(width: 8),
              const Text('Start Plan'),
            ],
          ),
        ),
        content: Text(
          plan.scheduledTasks.containsKey(dayName)
              ? 'Add today\'s tasks to your todo list?'
              : 'No tasks scheduled for today. Add next scheduled day\'s tasks?',
        ),
        actions: [
          TextButton(
            style: NeuConstants.neuBrutalismButtonStyle(
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: NeuConstants.neuBrutalismButtonStyle(
              color: plan.color,
            ),
            onPressed: () async {
              // If no tasks for today, find next scheduled day
              String targetDay = dayName;
              List<ScheduledTask>? tasksToAdd;

              if (!plan.scheduledTasks.containsKey(dayName)) {
                final weekDays = [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                  'Sunday'
                ];
                final todayIndex = weekDays.indexOf(dayName);

                for (int i = 1; i <= 7; i++) {
                  final nextDayIndex = (todayIndex + i) % 7;
                  if (plan.scheduledTasks.containsKey(weekDays[nextDayIndex])) {
                    targetDay = weekDays[nextDayIndex];
                    tasksToAdd = plan.scheduledTasks[targetDay];
                    break;
                  }
                }
              } else {
                tasksToAdd = plan.scheduledTasks[dayName];
              }

              if (tasksToAdd != null) {
                final todayStr = today.toIso8601String().split('T')[0];
                final existingTasksJson =
                    prefs.getStringList('tasks_$todayStr') ?? [];

                final existingTasks =
                    existingTasksJson.map((task) => jsonDecode(task)).toList();

                for (final task in tasksToAdd) {
                  existingTasks.add({
                    'title': task.title,
                    'isCompleted': false,
                  });
                }

                await prefs.setStringList(
                  'tasks_$todayStr',
                  existingTasks.map((task) => jsonEncode(task)).toList(),
                );

                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        dayName == targetDay
                            ? 'Today\'s tasks added to todo list!'
                            : '$targetDay\'s tasks added to todo list!',
                      ),
                      action: SnackBarAction(
                        label: 'VIEW',
                        onPressed: () {
                          DefaultTabController.of(context)
                              .animateTo(1); // Switch to Todo tab
                        },
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('START'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(WorkoutPlan plan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NeuConstants.neuBrutalismBoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(plan.icon, size: 24),
              const SizedBox(width: 12),
              Text(
                plan.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(plan.description),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: plan.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  plan.duration,
                  style: TextStyle(
                    color: plan.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  plan.difficulty,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('Scheduled Tasks'),
            children: [
              ...plan.scheduledTasks.entries.map((entry) {
                return _buildDayScheduler(
                  context,
                  entry.key,
                  entry.value,
                  (updatedTasks) {
                    setState(() {
                      plan.scheduledTasks[entry.key] = updatedTasks;
                    });
                    _savePlans();
                  },
                );
              }).toList(),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showPlanDetails(context, plan),
                        icon: const Icon(Icons.visibility),
                        label: const Text('VIEW'),
                        style: NeuConstants.neuBrutalismButtonStyle(),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _startPlan(context, plan),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('START'),
                        style: NeuConstants.neuBrutalismButtonStyle(
                          color: plan.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          // Show a confirmation dialog before deleting
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Delete Plan'),
                                content: const Text(
                                    'Are you sure you want to delete this plan?'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Close the dialog
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('Delete'),
                                    onPressed: () {
                                      setState(() {
                                        _plans.remove(plan); // Remove the plan
                                      });
                                      _savePlans();
                                      Navigator.of(context)
                                          .pop(); // Close the dialog
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('DELETE'),
                        style: NeuConstants.neuBrutalismButtonStyle(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabs() {
    return DefaultTabController(
      length: 7,
      child: Column(
        children: <Widget>[
          TabBar(
            tabs: const [
              Tab(text: 'Monday'),
              Tab(text: 'Tuesday'),
              Tab(text: 'Wednesday'),
              Tab(text: 'Thursday'),
              Tab(text: 'Friday'),
              Tab(text: 'Saturday'),
              Tab(text: 'Sunday'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _buildTasksForDay('Monday'),
                _buildTasksForDay('Tuesday'),
                _buildTasksForDay('Wednesday'),
                _buildTasksForDay('Thursday'),
                _buildTasksForDay('Friday'),
                _buildTasksForDay('Saturday'),
                _buildTasksForDay('Sunday'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksForDay(String day) {
    List<ScheduledTask> tasks =
        _getTasksForDay(day); // Retrieve tasks for the day

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                title: Text(task.title),
                subtitle: Text(
                    task.type.toString()), // Adjust to show task type if needed
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // Add functionality to delete the task
                    _deleteTask(day, task);
                  },
                ),
              );
            },
          ),
        ),
        ElevatedButton(
          onPressed: () {
            _addTaskDialog(context, day); // Show dialog to add a new task
          },
          child: const Text('Add Task'),
        ),
      ],
    );
  }

  void _addTaskDialog(BuildContext context, String day) {
    final TextEditingController _taskController = TextEditingController();
    final TextEditingController _customTaskTypeController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: SingleChildScrollView(
            // Wrap the Column in a SingleChildScrollView
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(labelText: 'Task Title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _customTaskTypeController,
                  decoration:
                      const InputDecoration(labelText: 'Custom Task Type'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newTask = ScheduledTask(
                  title: _taskController.text,
                  type: _customTaskTypeController.text.isNotEmpty
                      ? TaskType.custom
                      : TaskType.values.firstWhere(
                          (e) => e.toString() == 'exercise',
                          orElse: () => TaskType.exercise),
                  time: DateTime.now(), // Set the time as needed
                );
                _addTask(context, day, _getTasksForDay(day), (tasks) {
                  setState(() {
                    _plans
                        .firstWhere((plan) => plan.title == day)
                        .scheduledTasks[day] = tasks;
                  });
                  _savePlans();
                }); // Add the task to the day
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addTask(
    BuildContext context,
    String day,
    List<ScheduledTask> tasks,
    Function(List<ScheduledTask>) onTasksUpdated,
  ) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController _customTaskTypeController =
        TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    void _selectTime(BuildContext context) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: selectedTime,
      );
      if (picked != null && picked != selectedTime)
        setState(() {
          selectedTime = picked;
        });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: SingleChildScrollView(
            // Wrap the Column in a SingleChildScrollView
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Task Title'),
                ),
                TextField(
                  controller: _customTaskTypeController,
                  decoration:
                      const InputDecoration(labelText: 'Custom Task Type'),
                ),
                TextButton(
                  onPressed: () => _selectTime(context),
                  child: Text('Select Time: ${selectedTime.format(context)}'),
                ),
                // Additional fields for time and type can be added here
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newTask = ScheduledTask(
                  title: titleController.text,
                  type: _customTaskTypeController.text.isNotEmpty
                      ? TaskType.custom
                      : TaskType.values.firstWhere(
                          (e) => e.toString() == 'exercise',
                          orElse: () => TaskType.exercise),
                  time: DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                    selectedTime.hour,
                    selectedTime.minute,
                  ).toLocal(), // Use local time
                );
                tasks.add(newTask); // Add the task to the list
                onTasksUpdated(tasks); // Update the task list
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  List<ScheduledTask> _getTasksForDay(String day) {
    // Retrieve tasks for the specified day from the relevant plan
    return _plans.firstWhere((plan) => plan.title == day).scheduledTasks[day] ??
        [];
  }

  void _deleteTask(String day, ScheduledTask task) {
    setState(() {
      _plans
          .firstWhere((plan) => plan.title == day)
          .scheduledTasks[day]
          ?.remove(task);
    });
  }

  void _showCreatePlanDialog(BuildContext context) {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _durationController = TextEditingController();
    final TextEditingController _descriptionController = TextEditingController();
    // _difficulty will be local to the dialog state
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String _difficulty = 'Easy'; // Default value for this dialog
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Create New Plan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: _durationController,
                    decoration: const InputDecoration(labelText: 'Duration'),
                  ),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  DropdownButton<String>(
                    value: _difficulty,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _difficulty = newValue; // Update the difficulty
                        });
                      }
                    },
                    items: <String>['Easy', 'Medium', 'Hard']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final newPlan = WorkoutPlan(
                      title: _titleController.text,
                      duration: _durationController.text,
                      description: _descriptionController.text,
                      difficulty: _difficulty,
                      color: NeuConstants.primaryColor,
                      icon: Icons.fitness_center,
                      scheduledTasks: {
                        'Monday': [],
                        'Tuesday': [],
                        'Wednesday': [],
                        'Thursday': [],
                        'Friday': [],
                        'Saturday': [],
                        'Sunday': [],
                      },
                    );
                    setState(() {
                      _plans.add(newPlan);
                    });
                    _savePlans();
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _createNewPlan(String name) {
    setState(() {
      _plans.add(
        WorkoutPlan(
          title: name,
          duration: '',
          description: '',
          difficulty: '',
          color: NeuConstants.primaryColor,
          icon: Icons.fitness_center,
          scheduledTasks: {
            'Monday': [],
            'Tuesday': [],
            'Wednesday': [],
            'Thursday': [],
            'Friday': [],
            'Saturday': [],
            'Sunday': [],
          },
        ),
      );
    });
    _savePlans();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: NeuConstants.neuBrutalismBoxDecoration(
              color: Colors.white,
            ),
            child: const Row(
              children: [
                Icon(Icons.calendar_month, size: 24),
                SizedBox(width: 12),
                Text(
                  'Workout Plans',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Build plan cards directly in a Column instead of ListView.builder
          ..._plans
              .map((plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPlanCard(plan),
                  ))
              .toList(),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: NeuConstants.neuBrutalismBoxDecoration(
              color: NeuConstants.primaryColor,
            ),
            child: Column(
              children: [
                const Text(
                  'Create Custom Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showCreatePlanDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('NEW PLAN'),
                  style: NeuConstants.neuBrutalismButtonStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tozen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Version 1.1.3',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Developed by: CipheBloom',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Maintainer: Yougraj',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}