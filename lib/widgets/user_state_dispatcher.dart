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

     if (profileProvider.userProfile != null) {
      if (profileProvider.userProfile!.onboardingCompleted) {
        return const AppHubScreen();
      } else {
        return const OnboardingScreen();
      }
    }

    return const Scaffold(
      body: Center(
        child: Text("Error loading profile. Please restart the app."),
      ),
    );
  }
}