import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';
import '../screens/app_hub_screen.dart';
import '../screens/onboarding/onboarding_screen.dart'; 

class UserStateDispatcher extends StatelessWidget {
  const UserStateDispatcher({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the provider for changes to the user's profile or loading state.
    final profileProvider = context.watch<UserProfileProvider>();

    // DEBUG STEP 9: Log the state within the UserStateDispatcher
    if (kDebugMode) {
      print('[DEBUG 9] UserStateDispatcher: build method called.');
    }
    if (kDebugMode) {
      print(
        '[DEBUG 9] UserStateDispatcher: isLoading = ${profileProvider.isLoading}');
    }
    if (kDebugMode) {
      print(
        '[DEBUG 9] UserStateDispatcher: userProfile is null = ${profileProvider.userProfile == null}');
    }
    if (profileProvider.userProfile != null) {
      if (kDebugMode) {
        print(
          '[DEBUG 9] UserStateDispatcher: onboardingCompleted = ${profileProvider.userProfile!.onboardingCompleted}');
      }
    }

    // State 1: The user profile is being fetched.
    if (profileProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // State 2: The user profile has been successfully loaded.

     // 🛡️ SHIELD: Stage 4 Local-First Routing
    // Change: Added explicit handling for null profiles as a "New User" state.
    // Rationale: Resolves the hang on the error screen for users without an Isar record.

    // State 2: Explicitly handle Error status to differentiate from a missing profile.
    if (profileProvider.status == UserProfileStatus.error) {
      return const Scaffold(
        body: Center(
          child: Text("Error loading profile. Please restart the app."),
        ),
      );
    }

    // State 3: The user profile has been successfully loaded (or checked and found empty).
    // If the profile is null (New User) OR incomplete, route to Onboarding.
    if (profileProvider.userProfile == null || !profileProvider.userProfile!.onboardingCompleted) {
      if (kDebugMode) print('[DEBUG 9] UserStateDispatcher: Routing to OnboardingScreen.');
      return const OnboardingScreen();
    }

    // State 4: Profile exists and onboarding is complete.
    if (kDebugMode) print('[DEBUG 9] UserStateDispatcher: Routing to AppHubScreen.');
    return const AppHubScreen();
  }
}