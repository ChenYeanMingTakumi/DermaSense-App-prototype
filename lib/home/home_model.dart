import '../flutter_flow/flutter_flow_model.dart';
import 'home_widget.dart' show HomeWidget;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeModel extends FlutterFlowModel<HomeWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  
  // Auth service instance
  final AuthService _authService = AuthService();
  
  // User data
  String username = 'User';
  bool isLoading = true;
  
  @override
  void initState(BuildContext context) {
    loadUserData();
  }

  @override
  void dispose() {
    unfocusNode.dispose();
  }
  
  // Load user data from Firebase
  Future<void> loadUserData() async {
    try {
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
        } else {
          // Fallback to Firebase Auth display name
          username = currentUser.displayName ?? 'User';
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      username = 'User'; // Fallback
    } finally {
      isLoading = false;
    }
  }
  
  // Get current user
  User? get currentUser => _authService.currentUser;
  
  // Sign out user
  Future<void> signOut() async {
    await _authService.signOut();
  }
}
