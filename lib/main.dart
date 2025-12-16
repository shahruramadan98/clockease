import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'login_page.dart';
import 'auth_gate.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only once
  FirebaseApp firebaseApp;
  try {
    firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('[core/duplicate-app]')) {
      firebaseApp = Firebase.app(); // Get the already initialized default app
      print('Firebase already initialized');
    } else {
      rethrow;
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ClockEase',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
      routes: {
        '/home': (_) => const HomePage(),
      },
    );
  }
}


