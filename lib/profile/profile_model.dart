import '/flutter_flow/flutter_flow_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/auth_service.dart';
import 'profile_widget.dart' show ProfileWidget;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileModel extends FlutterFlowModel<ProfileWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();

  // Auth service instance
  final AuthService _authService = AuthService();

  // User data
  String username = 'User';
  String email = '';
  String phone = '';
  bool isLoading = true;

  @override
  void initState(BuildContext context) {
    loadUserData();
  }

  // Load user data from Firebase
  Future<void> loadUserData() async {
    try {
      isLoading = true;
      User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Try to get username from Firestore first
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.uid)
            .get();
            
        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          username = userData['username'] ?? currentUser.displayName ?? 'User';
          email = userData['email'] ?? currentUser.email ?? '';
          phone = userData['phone'] ?? '';
        } else {
          // Fallback to Firebase Auth display name and email
          username = currentUser.displayName ?? 'User';
          email = currentUser.email ?? '';
          phone = '';
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      username = 'User'; // Fallback
    } finally {
      isLoading = false;
    }
  }

  @override
  void dispose() {
    unfocusNode.dispose();
  }

  /// Sign out functionality
  Future<void> signOut(BuildContext context) async {
    try {
      // Sign out using AuthService
      final authService = AuthService();
      await authService.signOut();
    
      // Navigate to signin page after logout
      context.goNamed('signin');
    } catch (e) {
      // Show error message if sign out fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign out failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
