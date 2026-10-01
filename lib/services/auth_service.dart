import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    String? phone,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(username);
        
        // Create user document in Firestore
        await _createUserDocument(user, username, phone);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('General Error: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      print('Sign In Error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('General Error: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In process...');
      
      // Check if Google Play Services are available
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
      );
      
      // Sign out first to ensure fresh sign-in
      await googleSignIn.signOut();
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        print('Google Sign-In: User cancelled');
        return null;
      }

      print('Google Sign-In: User selected - ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw 'Failed to obtain Google authentication tokens';
      }

      print('Google Sign-In: Tokens obtained successfully');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Google Sign-In: Credential created, signing in to Firebase...');

      // Sign in to Firebase with the Google credential
      UserCredential result = await _auth.signInWithCredential(credential);
      
      User? user = result.user;
      if (user != null) {
        print('Google Sign-In: Firebase sign-in successful - ${user.email}');
        
        // Check if user document exists, if not create it
        DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
        if (!userDoc.exists) {
          print('Google Sign-In: Creating user document...');
          await _createUserDocument(user, user.displayName ?? 'User', null);
        } else {
          print('Google Sign-In: User document already exists');
          // For existing users, just update last sign in
          await updateLastSignIn();
        }
      }

      return result;
    } on FirebaseAuthException catch (e) {
      print('Google Sign-In Firebase Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw 'An account already exists with a different sign-in method.';
        case 'invalid-credential':
          throw 'The credential is invalid or has expired.';
        case 'operation-not-allowed':
          throw 'Google sign-in is not enabled for this project.';
        case 'user-disabled':
          throw 'This account has been disabled.';
        default:
          throw 'Google sign-in failed: ${e.message}';
      }
    } on PlatformException catch (e) {
      print('Google Sign-In Platform Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'sign_in_failed':
          throw 'Google sign-in failed. Please check your internet connection and try again.';
        case 'network_error':
          throw 'Network error. Please check your internet connection.';
        case 'sign_in_canceled':
          throw 'Sign-in was cancelled.';
        default:
          throw 'Google sign-in failed: ${e.message ?? 'Unknown error'}';
      }
    } catch (e) {
      print('Google Sign-In General Error: $e');
      throw 'Google sign-in failed. Please try again. Error: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Sign Out Error: $e');
      throw 'Sign out failed. Please try again.';
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String username, String? phone) async {
    try {
      await _firestore.collection('Users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'username': username,
        'phone': phone,
        'hasSeenWelcome': false, // Track if user has seen welcome page
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating user document: $e');
      // Don't throw error here as the user is already created in Auth
    }
  }

  // Check if user has seen welcome page
  Future<bool> hasUserSeenWelcome() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return true; // If no user, skip welcome
      
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['hasSeenWelcome'] ?? false;
      }
      return false; // If no document exists, show welcome
    } catch (e) {
      print('Error checking welcome status: $e');
      return true; // On error, skip welcome to avoid infinite loops
    }
  }

  // Mark user as having seen welcome page
  Future<void> markWelcomeAsSeen() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('Users').doc(user.uid).update({
          'hasSeenWelcome': true,
          'lastSignIn': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error marking welcome as seen: $e');
      // Don't throw error as this is not critical
    }
  }

  // Update last sign in time for existing users
  Future<void> updateLastSignIn() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('Users').doc(user.uid).update({
          'lastSignIn': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating last sign in: $e');
      // Don't throw error as this is not critical
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // Email validation
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Password validation
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw 'No user is currently signed in.';
      }

      // Re-authenticate user with current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      
      // Update user document in Firestore
      await _firestore.collection('Users').doc(user.uid).update({
        'lastPasswordChange': FieldValue.serverTimestamp(),
      });
      
    } on FirebaseAuthException catch (e) {
      print('Change Password Error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('General Error: $e');
      throw e.toString();
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String username,
    String? phone,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw 'No user is currently signed in.';
      }

      // Update display name in Firebase Auth
      await user.updateDisplayName(username);
      
      // Update user document in Firestore
      await _firestore.collection('Users').doc(user.uid).update({
        'username': username,
        'phone': phone,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
    } on FirebaseAuthException catch (e) {
      print('Update Profile Error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('General Error: $e');
      throw 'Failed to update profile. Please try again.';
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;
      
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Re-authenticate user
  Future<void> reauthenticateUser({
    required String password,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw 'No user is currently signed in.';
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      print('Re-authentication Error: ${e.message}');
      throw 'Authentication failed. Please check your current password.';
    }
  }
} 