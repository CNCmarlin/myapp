import 'package:flutter/material.dart';
import 'package:myapp/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/providers/date_provider.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/screens/nutrition_logging_screen.dart';
import 'package:myapp/screens/workout_screen.dart';
import 'package:myapp/screens/profile_screen.dart';
import 'package:myapp/screens/insights_screen.dart'; // NEW: Import the insights screen

class AppHubScreen extends StatefulWidget {
  const AppHubScreen({super.key});

  @override
  State<AppHubScreen> createState() => _AppHubScreenState();
}

class _AppHubScreenState extends State<AppHubScreen> {
  int _selectedIndex = 0;
  final GlobalKey<NutritionLoggingScreenState> _nutritionScreenKey =
      GlobalKey<NutritionLoggingScreenState>();

  final _newProgramNameController = TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showCreateProgramDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final firestoreService = FirestoreService();
        return AlertDialog(
          title: const Text('Create New Program'),
          content: TextField(
            controller: _newProgramNameController,
            decoration: const InputDecoration(labelText: 'Program Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _newProgramNameController.clear();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final programName = _newProgramNameController.text.trim();
                if (programName.isNotEmpty) {
                  final userId = context.read<AuthService>().currentUser?.uid;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error: You are not signed in.')),
                    );
                    return;
                  }
                  Navigator.of(dialogContext).pop();
                  await firestoreService.createNewWorkoutProgram(userId, programName);
                  _newProgramNameController.clear();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: Provider.of<DateProvider>(context, listen: false).selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      Provider.of<DateProvider>(context, listen: false).updateDate(picked);
    }
  }

  Widget? _buildFloatingActionButton() {
  switch (_selectedIndex) {
    case 0: // Workout
      return FloatingActionButton(
        onPressed: _showCreateProgramDialog,
        tooltip: 'Create New Program',
        child: const Icon(Icons.add),
      );
    
    // FIX: The Nutrition screen now manages its own FAB.
    // We let this case fall through to the default, which returns null.
    case 1: // Nutrition
    case 2: // Profile
    case 3: // Insights
    default:
      return null; // No central FAB for these screens.
  }
}

  @override
  Widget build(BuildContext context) {
    // NEW: Add InsightsScreen to the list of pages
    final List<Widget> pages = <Widget>[
      const DashboardScreen(),
      const WorkoutScreen(),
      NutritionLoggingScreen(key: _nutritionScreenKey),
      const ProfileScreen(),
      const InsightsScreen(),
    ];
    // NEW: Add "Insights" to the titles list
    final List<String> titles = <String>[
      'AI Assistant',
      'Nutrition Log',
      'Profile',
      'AI Coach Insights',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${titles[_selectedIndex]} - ${DateFormat('yyyy-MM-dd').format(context.watch<DateProvider>().selectedDate)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        // NEW: Add a new item for the Insights tab
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.food_bank_outlined),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Insights',
          ),
        ],
        currentIndex: _selectedIndex,
        // IMPORTANT: For more than 3 items, you need to set the type
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
}