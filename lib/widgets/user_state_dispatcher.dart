import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/user_profile_provider.dart';
import 'package:myapp/screens/app_hub_screen.dart';
import 'package:myapp/screens/onboarding_screen.dart';

class UserStateDispatcher extends StatelessWidget {
  const UserStateDispatcher({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the provider for changes to the user's profile or loading state.
    final profileProvider = context.watch<UserProfileProvider>();
    
    // DEBUG STEP 9: Log the state within the UserStateDispatcher
    print('[DEBUG 9] UserStateDispatcher: build method called.');
    print('[DEBUG 9] UserStateDispatcher: isLoading = ${profileProvider.isLoading}');
    print('[DEBUG 9] UserStateDispatcher: userProfile is null = ${profileProvider.userProfile == null}');
    if (profileProvider.userProfile != null) {
      print('[DEBUG 9] UserStateDispatcher: onboardingCompleted = ${profileProvider.userProfile!.onboardingCompleted}');
    }

    // State 1: The user profile is being fetched.
    if (profileProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // State 2: The user profile has been successfully loaded.
    if (profileProvider.userProfile != null) {
      // Check the onboarding flag to decide which screen to show.
      if (profileProvider.userProfile!.onboardingCompleted) {
        // The user is fully set up, show the main app.
        return const AppHubScreen();
      } else {
        // The user is new and needs to complete onboarding.
        return const OnboardingScreen();
      }
    }

    // Edge Case: The user is logged in, but we failed to get a profile.
    // This could be a temporary error. Showing a loading screen is a safe fallback.
    return const Scaffold(
      body: Center(
        child: Text("Error loading profile. Please restart the app."),
      ),
    );
  }
}