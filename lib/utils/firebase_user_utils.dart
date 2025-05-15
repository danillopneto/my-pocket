import 'package:firebase_auth/firebase_auth.dart';

/// Utility function to run an action with the current user if logged in.
T? withCurrentUser<T>(T Function(User user) action) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  return action(user);
}

/// Async version for actions that return a Future.
Future<T?> withCurrentUserAsync<T>(Future<T> Function(User user) action) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  return await action(user);
}
