import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/user_service.dart';

/// ===============================
/// AUTH STATE PROVIDER
/// ===============================
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// ===============================
/// USER SERVICE PROVIDER
/// ===============================
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

/// ===============================
/// PROFILE PROVIDER (AUTH-AWARE)
/// ===============================
final profileProvider = StreamProvider<UserProfile?>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return authAsync.when(
    data: (user) {
      // 🔒 Logged out → no profile stream
      if (user == null) {
        return const Stream.empty();
      }

      // ✅ Logged in → stream profile using UID
      final userService = ref.read(userServiceProvider);
      return userService.getEmployeeProfileStream(user.uid);
    },

    // While auth state is resolving
    loading: () => const Stream.empty(),

    // In case auth stream errors
    error: (_, __) => const Stream.empty(),
  );
});

