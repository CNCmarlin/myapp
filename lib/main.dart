// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/providers/nutrition_log_provider.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import '../providers/date_provider.dart';
import '../providers/chat_provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/auth_wrapper.dart';
import '../providers/insights_provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import '../providers/workout_provider.dart'; // NEW IMPORT

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final localStorageService =
      LocalStorageService(); // Change: Initialize local service
  await localStorageService
      .init(); // Change: Ensure Isar is ready before providers start

  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? AndroidDebugProvider() // Use the class
        : AndroidPlayIntegrityProvider(), // Use the recommended class
  );

  runApp(
    MultiProvider(
      providers: [
        // Foundational Services
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<LocalStorageService>(
            create: (_) =>
                localStorageService), // Change: Inject local storage as a foundational service

        // App State Providers
        // ChangeNotifierProvider(create: (_) => ChatProvider()), // REMOVE THIS LINE
        ChangeNotifierProvider(create: (_) => DateProvider()),

        ChangeNotifierProvider(
          create: (context) => InsightsProvider(
            authService: context.read<AuthService>(),
            firestoreService: context.read<FirestoreService>(),
          ),
        ),

        // UserProfileProvider is now focused solely on the user's profile.
        ChangeNotifierProvider(
          create: (context) => UserProfileProvider(
            authService: context.read<AuthService>(),
            // Fix: Swapped legacy FirestoreService for LocalStorageService
            localStorageService: context.read<LocalStorageService>(),
          ),
        ),

        // WorkoutProvider manages workout programs.
        ChangeNotifierProxyProvider<UserProfileProvider, WorkoutProvider>(
          create: (context) => WorkoutProvider(
            authService: context.read<AuthService>(),
            localStorageService: context.read<LocalStorageService>(),
            userProfileProvider: context.read<UserProfileProvider>(),
          ),
          update: (context, userProfileProvider, previousWorkoutProvider) =>
              WorkoutProvider(
            authService: context.read<AuthService>(),
            localStorageService: context.read<LocalStorageService>(),
            userProfileProvider: userProfileProvider,
          ),
        ),

        ChangeNotifierProxyProvider2<UserProfileProvider, DateProvider,
            NutritionLogProvider>(
          create: (context) => NutritionLogProvider(
            userId: context.read<AuthService>().currentUser?.uid ?? '',
            date: context.read<DateProvider>().selectedDate,
            authService: context.read<AuthService>(), // ADD THIS
            localStorageService: context.read<LocalStorageService>(),
          ),
          update: (context, userProfileProvider, dateProvider,
              previousNutritionLogProvider) {
            final userId = context.read<AuthService>().currentUser?.uid ?? '';
            final newProfile = userProfileProvider.userProfile;
            final newDate = dateProvider.selectedDate;

            if (previousNutritionLogProvider == null || userId.isEmpty) {
              // Inside MultiProvider -> ChangeNotifierProxyProvider2
              return NutritionLogProvider(
                userId: userId,
                date: newDate,
                userProfile: newProfile,
                authService: context.read<AuthService>(),
                localStorageService:
                    context.read<LocalStorageService>(), // ADD THIS LINE
              );
            }

            previousNutritionLogProvider.updateDependencies(
                newDate, newProfile);
            return previousNutritionLogProvider;
          },
        ),

        // CORRECTED: This single entry for ChatProvider handles all dependencies.
        ChangeNotifierProxyProvider2<UserProfileProvider, WorkoutProvider,
            ChatProvider>(
          create: (context) => ChatProvider(
            userProfileProvider: context.read<UserProfileProvider>(),
            workoutProvider: context.read<WorkoutProvider>(),
            authService: context.read<AuthService>(), // Add this line
          ),
          update: (context, userProfileProvider, workoutProvider,
                  previousChatProvider) =>
              ChatProvider(
            userProfileProvider: userProfileProvider,
            workoutProvider: workoutProvider,
            authService: context.read<AuthService>(), // Add this line
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SimplyFit',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
