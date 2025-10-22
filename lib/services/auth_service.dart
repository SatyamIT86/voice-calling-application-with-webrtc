// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'dart:async';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Timeout duration for Firebase operations
  static const Duration _operationTimeout = Duration(seconds: 30);

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('Starting sign up for: $email');

      // Create user with timeout
      final userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            _operationTimeout,
            onTimeout: () => throw TimeoutException('Sign up timed out'),
          );

      print('User created: ${userCredential.user?.uid}');

      // Update display name
      await userCredential.user
          ?.updateDisplayName(name)
          .timeout(
            _operationTimeout,
            onTimeout: () =>
                throw TimeoutException('Display name update timed out'),
          );

      print('Display name updated');

      // Create user document in Firestore
      await _createUserDocument(
        userId: userCredential.user!.uid,
        email: email,
        name: name,
      );

      print('Sign up completed successfully');
      return userCredential;
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      throw Exception(
        'Sign up timeout. Please check your internet connection.',
      );
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected sign up error: $e');
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('Starting sign in for: $email');

      final userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(
            _operationTimeout,
            onTimeout: () => throw TimeoutException('Sign in timed out'),
          );

      print('Sign in successful: ${userCredential.user?.uid}');
      return userCredential;
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      throw Exception('Login timeout. Please check your internet connection.');
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected sign in error: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument({
    required String userId,
    required String email,
    required String name,
  }) async {
    try {
      print('Creating user document for: $userId');

      final userModel = UserModel(
        id: userId,
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .set(userModel.toMap(), SetOptions(merge: true))
          .timeout(
            _operationTimeout,
            onTimeout: () =>
                throw TimeoutException('Firestore write timed out'),
          );

      print('User document created successfully for: $userId');
    } on TimeoutException catch (e) {
      print('Firestore timeout: $e');
      // Don't throw here - user is created, just document creation failed
      // They can still use the app
      print(
        'Warning: User document creation timed out, but user account exists',
      );
    } on FirebaseException catch (e) {
      print('Firestore error: ${e.code} - ${e.message}');
      // Don't throw - user account is created
      print('Warning: User document creation failed, but user account exists');
    } catch (e) {
      print('Error creating user document: $e');
      // Don't throw - user account is created
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String userId) async {
    try {
      print('Fetching user data for: $userId');

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(
            _operationTimeout,
            onTimeout: () => throw TimeoutException('Firestore read timed out'),
          );

      if (doc.exists) {
        print('User data found');
        return UserModel.fromMap(doc.data()!);
      }
      print('User data not found');
      return null;
    } on TimeoutException catch (e) {
      print('Timeout getting user data: $e');
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user signed in');

      print('Updating user profile for: ${user.uid}');

      if (displayName != null) {
        await user
            .updateDisplayName(displayName)
            .timeout(
              _operationTimeout,
              onTimeout: () =>
                  throw TimeoutException('Display name update timed out'),
            );
      }
      if (photoUrl != null) {
        await user
            .updatePhotoURL(photoUrl)
            .timeout(
              _operationTimeout,
              onTimeout: () =>
                  throw TimeoutException('Photo URL update timed out'),
            );
      }

      // Update Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
            if (displayName != null) 'name': displayName,
            if (photoUrl != null) 'photo_url': photoUrl,
          })
          .timeout(
            _operationTimeout,
            onTimeout: () =>
                throw TimeoutException('Firestore update timed out'),
          );

      print('Profile updated successfully');
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      throw Exception(
        'Profile update timeout. Please check your internet connection.',
      );
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      print('Sending password reset email to: $email');

      await _auth
          .sendPasswordResetEmail(email: email)
          .timeout(
            _operationTimeout,
            onTimeout: () => throw TimeoutException('Password reset timed out'),
          );

      print('Password reset email sent');
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      throw Exception(
        'Password reset timeout. Please check your internet connection.',
      );
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Error resetting password: $e');
      throw Exception('Password reset failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('Signing out user');

      await _auth.signOut().timeout(
        _operationTimeout,
        onTimeout: () => throw TimeoutException('Sign out timed out'),
      );

      print('Sign out successful');
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      throw Exception(
        'Sign out timeout. Please check your internet connection.',
      );
    } catch (e) {
      print('Error signing out: $e');
      throw Exception('Sign out failed: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user signed in');

      print('Deleting account for: ${user.uid}');

      // Delete user document from Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .delete()
          .timeout(
            _operationTimeout,
            onTimeout: () =>
                throw TimeoutException('Firestore delete timed out'),
          );

      // Delete user account
      await user.delete().timeout(
        _operationTimeout,
        onTimeout: () => throw TimeoutException('Account deletion timed out'),
      );

      print('Account deleted successfully');
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      throw Exception(
        'Account deletion timeout. Please check your internet connection.',
      );
    } catch (e) {
      print('Error deleting account: $e');
      throw Exception('Account deletion failed: $e');
    }
  }

  // Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign in is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      default:
        return 'Authentication error: ${e.message ?? e.code}';
    }
  }

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Get current user ID
  String? get currentUserId => currentUser?.uid;

  // Get current user email
  String? get currentUserEmail => currentUser?.email;

  // Get current user name
  String? get currentUserName => currentUser?.displayName;

  // Persistence configuration (for web only)
  Future<void> setPersistence() async {
    try {
      // Note: setPersistence is only available on web platform
      // On mobile, auth state is automatically persisted
      print('Auth persistence: Native mobile persistence active');
    } catch (e) {
      print('Error setting persistence: $e');
    }
  }
}
