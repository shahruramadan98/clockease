import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider((ref) => UserService());

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final userService = ref.read(userServiceProvider);
  return await userService.getEmployeeProfile();
});
