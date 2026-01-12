import 'package:flutter/material.dart';
//import '../models/workout_data.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/providers/insights_provider.dart';
import 'package:myapp/screens/workout_history_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../screens/dashboard_screen.dart';
import '../providers/date_provider.dart';
import '../screens/nutrition_logging_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/insights_screen.dart';
import '../screens/workout_screen.dart';

class AppHubScreen extends StatefulWidget {
  const AppHubScreen({super.key});

  @override
  State<AppHubScreen> createState() => _AppHubScreenState();
}

class _AppHubScreenState extends State<AppHubScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          Provider.of<DateProvider>(context, listen: false).selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      Provider.of<DateProvider>(context, listen: false).updateDate(picked);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return DateFormat('E, MMM d').format(date); // e.g., "Tue, Aug 19"
    }
  }

// NEW: Method to build the correct FAB based on the selected index
  Widget? _buildFab(BuildContext context) {
    switch (_selectedIndex) {
      case 1: // Workout Screen
        return FloatingActionButton.extended(
          heroTag: 'workout_history_fab', // Unique tag
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkoutHistoryScreen(),
              ),
            );
          },
          label: const Text('History'),
          icon: const Icon(Icons.history),
        );
      case 3: // Insights Screen (previously index 4, now 3)
        return FloatingActionButton.extended(
          heroTag: 'insights_fab', // Unique tag
          onPressed: () {
            // This logic needs a way to access the provider or pass the context.
            // For now, we'll just show the options.
            _showInsightGenerationOptions(context);
          },
          label: const Text("Generate"),
          icon: const Icon(Icons.auto_awesome),
        );
      default:
        return null; // No FAB for other screens
    }
  }

  // NEW: Copied from the insights screen to be accessible here
  void _showInsightGenerationOptions(BuildContext context) {
    final provider = context.read<InsightsProvider>();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.show_chart),
                title: const Text('Generate Weekly Workout Report'),
                onTap: () {
                  Navigator.pop(context);
                  provider.generateNewWorkoutInsight(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.fastfood_outlined),
                title: const Text('Generate Weekly Nutrition Report'),
                onTap: () {
                  Navigator.pop(context);
                  provider.generateNewNutritionInsight(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text('Generate Weekly Summary'),
                onTap: () {
                  Navigator.pop(context);
                  provider.generateNewSummaryInsight(context, isMonthly: false);
                },
              ),
               ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Generate Monthly Summary'),
                onTap: () {
                  Navigator.pop(context);
                  provider.generateNewSummaryInsight(context, isMonthly: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildCustomAppBar(BuildContext context) {
    final dateProvider = context.watch<DateProvider>();

    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: AppBar(
        title: GestureDetector(
          onTap: () => _selectDate(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SIMPLY FIT',
                style: GoogleFonts.bebasNeue( // Example of a stylized font
                  fontSize: 24,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                _formatDate(dateProvider.selectedDate),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                // Navigate to the ProfileScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              customBorder: const CircleBorder(),
              child: const CircleAvatar(
                // Placeholder for user avatar
                child: Icon(Icons.person_outline),
              ),
            ),
          ),
        ],
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    // UPDATED: Removed ProfileScreen from the main page list
    final List<Widget> pages = <Widget>[
      const DashboardScreen(),
      const WorkoutScreen(),
      const NutritionLoggingScreen(),
      const InsightsScreen(),
    ];

    // UPDATED: Removed the Profile tab from the bottom navigation bar
    final List<BottomNavigationBarItem> navBarItems = const <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Assistant',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.fitness_center_outlined),
        label: 'Workout',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.food_bank_outlined),
        label: 'Nutrition',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.auto_awesome_outlined),
        label: 'Insights',
      ),
    ];

    return Scaffold(
      // Use the new custom app bar
      appBar: _buildCustomAppBar(context),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: navBarItems,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _buildFab(context),
    );
  }
}