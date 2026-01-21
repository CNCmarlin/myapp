// lib/screens/onboarding/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../providers/user_profile_provider.dart';
import 'pages/api_key_page.dart';
import 'pages/welcome_page.dart';
import 'pages/goal_page.dart';
import 'pages/unit_system_page.dart';
import 'pages/biometrics_page.dart';
import 'pages/diet_and_activity_page.dart';
import 'pages/fitness_proficiency_page.dart';
import '../shared/equipment_manager_screen.dart';
import 'pages/create_program_page.dart';
import 'pages/nutrition_goals_page.dart';
import 'pages/summary_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _goalFormKey = GlobalKey<FormState>();
  final _biometricsFormKey = GlobalKey<FormState>();
  final _dietActivityFormKey = GlobalKey<FormState>();
  final _programFormKey = GlobalKey<FormState>();
  final _nutritionFormKey = GlobalKey<FormState>();

  late final List<Widget> _pages;

 bool _isCurrentPageValid = true;

  @override
  void initState() {
    super.initState();
    _pages = [
      const WelcomePage(),
      ApiKeyPage(onValidationChanged: (isValid) {
    setState(() => _isCurrentPageValid = isValid);
  }),
      GoalPage(formKey: _goalFormKey),
      const UnitSystemPage(),
      BiometricsPage(formKey: _biometricsFormKey),
      DietAndActivityPage(formKey: _dietActivityFormKey),
      const FitnessProficiencyPage(),
      const EquipmentManagerScreen(isOnboarding: true),
      CreateProgramPage(formKey: _programFormKey),
      NutritionGoalsPage(formKey: _nutritionFormKey),
      const SummaryPage(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage(BuildContext context) {
    bool canProceed = true;
    String errorMessage = '';

    // 🛡️ SHIELD: Shifted Navigation Indices
    // Change: Updated switch cases to account for ApiKeyPage insertion at index 1.
    // Rationale: Realigns form validation with the correct pages in the sequence.
    switch (_currentPage) {
      case 2: // GoalPage (was 1)
        canProceed = _goalFormKey.currentState?.validate() ?? false;
        break;
      case 4: // BiometricsPage (was 3)
        canProceed = _biometricsFormKey.currentState?.validate() ?? false;
        break;
      case 5: // DietAndActivityPage (was 4)
        canProceed = _dietActivityFormKey.currentState?.validate() ?? false;
        break;
      // 📍 Change: Shifted subsequent page indices down to accommodate EquipmentManager at index 7
      case 8: // CreateProgramPage (was 7)
        canProceed = context.read<OnboardingProvider>().finalProfile.activeProgramId != null;
        if (!canProceed) errorMessage = 'Please create and save a program to continue.';
        break;
      case 9: // NutritionGoalsPage (was 8)
        canProceed = _nutritionFormKey.currentState?.validate() ?? false;
        break;
    }

    if (canProceed) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else if (errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  void _completeOnboarding(BuildContext context) async {
    final userProfileProvider = context.read<UserProfileProvider>();
    final onboardingProvider = context.read<OnboardingProvider>();

    final finalProfile = onboardingProvider.finalProfile.copyWith(
      onboardingCompleted: true,
      activeProgramId: onboardingProvider.finalProfile.activeProgramId,
    );

    userProfileProvider.setInitialProfile(finalProfile);
    await userProfileProvider.saveProfileChanges();
  }

  @override
  Widget build(BuildContext context) {
    // 🛡️ SHIELD: Redundant Provider Removal
    // Change: Removed ChangeNotifierProvider and internal Builder.
    // Rationale: State is now managed globally in main.dart, resolving routing exceptions.
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: _pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: (_currentPage == 1 && !_isCurrentPageValid)
                        ? null
                        : () {
                            if (_currentPage == _pages.length - 1) {
                              _completeOnboarding(context); // 📍 Change: Use standard context
                            } else {
                              _nextPage(context); // 📍 Change: Use standard context
                            }
                          },
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Complete Setup' : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}