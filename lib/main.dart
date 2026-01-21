// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myapp/providers/nutrition_log_provider.dart';
import 'package:provider/provider.dart';
import '../providers/date_provider.dart';
import '../providers/chat_provider.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../services/google_drive_service.dart';
import '../services/secure_storage_service.dart';
import '../services/sync_service.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/auth_wrapper.dart';
import '../providers/insights_provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import '../providers/workout_provider.dart';
import 'providers/onboarding_provider.dart';
import 'services/ai_service.dart';
import 'services/assistant_service.dart';
import 'services/insights_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        Provider<LocalStorageService>(create: (_) => localStorageService),
        Provider<SecureStorageService>(create: (_) => const SecureStorageService()),

        Provider<AIService>(
          create: (context) => AIService(
            secureStorage: context.read<SecureStorageService>(),
          ),
        ),
        Provider<AssistantService>(
          create: (context) => AssistantService(
            secureStorage: context.read<SecureStorageService>(),
          ),
        ),
        Provider<GoogleDriveService>(
          create: (context) => GoogleDriveService(
            context.read<AuthService>().googleSignIn,
          ),
        ),
        Provider<SyncService>(
          create: (context) => SyncService(
            storageService: context.read<LocalStorageService>(),
            driveService: context.read<GoogleDriveService>(),
          ),
        ),
        
        ChangeNotifierProvider(create: (_) => DateProvider()),

        Provider<InsightsService>(
          create: (context) => InsightsService(
            aiService: context.read<AIService>(),
            storage: context.read<LocalStorageService>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (context) => InsightsProvider(
            authService: context.read<AuthService>(),
            localStorageService: context.read<LocalStorageService>(),
            insightsService: context.read<InsightsService>(),
          ),
        ),

        // UserProfileProvider is now the coordinator for local data and cloud sync.
        ChangeNotifierProvider(
          create: (context) => UserProfileProvider(
            authService: context.read<AuthService>(),
            localStorageService: context.read<LocalStorageService>(),
            syncService: context.read<SyncService>(),
            aiService: context.read<AIService>(),
            
          ),
        ),

        ChangeNotifierProvider(create: (_) => OnboardingProvider()),

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
            // Fix: Replaced authService with secureStorageService to match new constructor
            secureStorageService: context.read<SecureStorageService>(), 
            localStorageService: context.read<LocalStorageService>(),
            userProfileProvider: context.read<UserProfileProvider>(),
          ),
          update: (context, userProfileProvider, dateProvider,
              previousNutritionLogProvider) {
            final userId = context.read<AuthService>().currentUser?.uid ?? '';
            final newProfile = userProfileProvider.userProfile;
            final newDate = dateProvider.selectedDate;

            if (previousNutritionLogProvider == null || userId.isEmpty) {
              return NutritionLogProvider(
                userId: userId,
                date: newDate,
                // Fix: Replaced authService with secureStorageService here as well
                secureStorageService: context.read<SecureStorageService>(),
                localStorageService: context.read<LocalStorageService>(),
                userProfileProvider: userProfileProvider,
              );
            }

            previousNutritionLogProvider.updateDependencies(
                newDate, newProfile);
            return previousNutritionLogProvider;
          },
        ),

        // CORRECTED: Added localStorageService injection to both initialization blocks
        ChangeNotifierProxyProvider2<UserProfileProvider, WorkoutProvider,
            ChatProvider>(
          create: (context) => ChatProvider(
            userProfileProvider: context.read<UserProfileProvider>(),
            workoutProvider: context.read<WorkoutProvider>(),
            localStorageService:
                context.read<LocalStorageService>(), // Fix: Pass local storage
                assistantService: context.read<AssistantService>(),
          ),
          update: (context, userProfileProvider, workoutProvider,
                  previousChatProvider) =>
              ChatProvider(
            userProfileProvider: userProfileProvider,
            workoutProvider: workoutProvider,
            localStorageService:
                context.read<LocalStorageService>(), // Fix: Pass local storage
                assistantService: context.read<AssistantService>(),
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
