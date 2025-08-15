import 'package:flutter/material.dart';
//import 'package:myapp/models/workout_data.dart';
//import 'package:myapp/providers/profile_provider.dart';
import 'package:myapp/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:myapp/screens/dashboard_screen.dart';
import 'package:myapp/providers/date_provider.dart';
import 'package:myapp/screens/nutrition_logging_screen.dart';
import 'package:myapp/screens/profile_screen.dart';
import 'package:myapp/screens/insights_screen.dart';
import 'package:myapp/screens/workout_screen.dart';

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
      initialDate: Provider.of<DateProvider>(context, listen: false).selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      Provider.of<DateProvider>(context, listen: false).updateDate(picked);
    }
  }

  AppBar _buildAppBar(BuildContext context) {
  final dateProvider = context.watch<DateProvider>();
  final userProfileProvider = context.watch<UserProfileProvider>();
  final dateString = DateFormat('yyyy-MM-dd').format(dateProvider.selectedDate);

  final List<String> titles = <String>[
    'AI Assistant', 'Workout Log', 'Nutrition Log', 'Profile', 'AI Coach Insights',
  ];
  
  // This condition is no longer needed as the WorkoutScreen now has its own AppBar
  // if (_selectedIndex == 1) { ... }

  return AppBar(
    title: Text('${titles[_selectedIndex]} - $dateString'),
    actions: [
      IconButton(
        icon: const Icon(Icons.calendar_today),
        onPressed: () => _selectDate(context),
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const DashboardScreen(),
      const WorkoutScreen(),
      const NutritionLoggingScreen(),
      const ProfileScreen(),
      const InsightsScreen(),
    ];
    
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
        icon: Icon(Icons.person_outline),
        label: 'Profile',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.auto_awesome_outlined),
        label: 'Insights',
      ),
    ];

    return Scaffold(
      appBar: _buildAppBar(context),
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
    );
  }
}