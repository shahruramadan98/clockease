import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider((ref) => UserService());

final profileProvider = StreamProvider<UserProfile?>((ref) {
  final userService = ref.read(userServiceProvider);
  
  // Trigger auto-creation in the background if it doesn't exist
  // This ensures that even if the stream starts empty, the profile is created.
  userService.getEmployeeProfile(); 

  return userService.getUserProfileStream();
});
