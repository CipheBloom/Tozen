import 'package:flutter/material.dart';
import '../constants/neu_constants.dart';
import 'workout_screen.dart';
import 'todo_screen.dart';
import 'plans_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: NeuConstants.backgroundColor,
        appBar: AppBar(
          title: Container(
            padding: const EdgeInsets.all(8),
            decoration: NeuConstants.neuBrutalismBoxDecoration(
              color: NeuConstants.primaryColor,
              offsetX: 2,
              offsetY: 2,
            ),
            child: const Text(
              'FITNESS PLANNER',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showAboutDialog(context),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(65),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: NeuConstants.neuBrutalismBoxDecoration(
                color: Colors.white,
                offsetX: 2,
                offsetY: 2,
              ),
              child: TabBar(
                labelPadding: EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                indicator: BoxDecoration(
                  color: NeuConstants.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black54,
                tabs: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center, size: 20),
                          Text(
                            'WORKOUTS',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.checklist, size: 20),
                          Text(
                            'TODO',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month, size: 20),
                          Text(
                            'PLANS',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            WorkoutScreen(),
            TodoScreen(),
            PlansScreen(),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
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
            color: NeuConstants.primaryColor,
            offsetX: 2,
            offsetY: 2,
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 8),
              Text('ABOUT'),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: NeuConstants.neuBrutalismBoxDecoration(
                color: Colors.white,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tozen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Version: 1.0.0'),
                  SizedBox(height: 8),
                  Text('Developed by: CipheBloom'),
                  SizedBox(height: 8),
                  Text('Maintainer: Yougraj'),
                  SizedBox(height: 8),
                  Text(' 2024 All rights reserved'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: NeuConstants.neuBrutalismBoxDecoration(
              color: NeuConstants.secondaryColor,
              offsetX: 2,
              offsetY: 2,
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
