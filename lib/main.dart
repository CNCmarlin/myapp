import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/providers/profile_provider.dart'; // NEW
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/date_provider.dart';
import 'package:myapp/providers/chat_provider.dart'; // NEW
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/providers/user_profile_provider.dart';
import 'package:myapp/widgets/auth_wrapper.dart';
import 'package:myapp/providers/insights_provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // This is the definitive, environment-aware setup for App Check.
  await FirebaseAppCheck.instance.activate(
    // It will use the Debug Provider for debug builds...
    // ...and the Play Integrity provider for all release builds.
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
  );

  FirebaseAppCheck.instance.onTokenChange.listen((token) {
    print("App Check DEBUG TOKEN: $token");
  });

  runApp(
    MultiProvider(
      providers: [
        // Foundational Services
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),

        // App State Providers
        ChangeNotifierProvider(create: (_) => ChatProvider()), // NEW
        ChangeNotifierProvider(create: (_) => DateProvider()),

        ChangeNotifierProvider(
          create: (context) => InsightsProvider(
            authService: context.read<AuthService>(),
          ),
        ),

        // UserProfileProvider is independent
        ChangeNotifierProvider(
          create: (context) => UserProfileProvider(
            authService: context.read<AuthService>(),
            firestoreService: context.read<FirestoreService>(),
          ),
        ),

        // NEW: ProfileProvider depends on other providers, so we use ChangeNotifierProxyProvider
        ChangeNotifierProxyProvider<UserProfileProvider, ProfileProvider>(
          create: (context) => ProfileProvider(
            authService: context.read<AuthService>(),
            firestoreService: context.read<FirestoreService>(),
            userProfileProvider: context.read<UserProfileProvider>(),
          ),
          update: (context, userProfileProvider, previousProfileProvider) =>
              ProfileProvider(
            authService: context.read<AuthService>(),
            firestoreService: context.read<FirestoreService>(),
            userProfileProvider: userProfileProvider, // The important update
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
