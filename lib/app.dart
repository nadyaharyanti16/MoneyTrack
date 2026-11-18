
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/splash_screen.dart';
import 'screens/main_navigation.dart';

class MoneyTrackApp extends StatelessWidget {
  const MoneyTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MoneyTrack',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5267D8),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F6FA),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5267D8),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return const MainNavigation();
        }

        return const SplashScreen();
      },
    );
  }
}
