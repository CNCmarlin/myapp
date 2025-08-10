import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'package:myapp/screens/app_hub_screen.dart'; // Adjust import if needed
import 'package:myapp/screens/login_screen.dart'; // Adjust import if needed
import 'package:myapp/widgets/user_state_dispatcher.dart';
import 'package:myapp/services/auth_service.dart'; // Adjust import if needed
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while waiting for the initial auth state
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          // User is signed in, show the main app screen
          return const UserStateDispatcher();
        } else {
          // User is signed out, show the login screen
          return const LoginScreen();
        }
      },
    );
  }
}