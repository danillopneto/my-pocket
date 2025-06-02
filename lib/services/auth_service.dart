// Handles authentication (Google Sign-In and Email/Password)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get userChanges => _auth.userChanges();
  Future<User?> signInWithGoogle({BuildContext? context}) async {
    if (kIsWeb) {
      try {
        // On web, we're using the Google Identity Services API via our custom button
        // The button triggers this method when clicked
        // Use Firebase's built-in web auth provider
        final provider = GoogleAuthProvider();
        // Add scope for profile and email
        provider.addScope('profile');
        provider.addScope('email');

        // Sign in with popup (more reliable than redirect on web)
        final userCredential = await _auth.signInWithPopup(provider);
        return userCredential.user;
      } catch (e) {
        return null;
      }
    } else {
      // Mobile/desktop: use the old flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  // Email/Password Authentication Methods

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException {
      return null;
    }
  }

  // Sign up with email and password
  Future<User?> signUpWithEmail(String email, String password,
      {String? firstName, String? lastName}) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Optionally update displayName with first and last name
      if (userCredential.user != null &&
          (firstName != null || lastName != null)) {
        String displayName = '';
        if (firstName != null) displayName += firstName;
        if (lastName != null) {
          displayName += (displayName.isNotEmpty ? ' ' : '') + lastName;
        }
        await userCredential.user!.updateDisplayName(displayName);
      }
      return userCredential.user;
    } on FirebaseAuthException {
      return null;
    }
  }

  // Reset password
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }
}
