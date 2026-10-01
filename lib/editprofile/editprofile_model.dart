import '../flutter_flow/flutter_flow_model.dart';
import 'editprofile_widget.dart' show EditprofileWidget;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class EditprofileModel extends FlutterFlowModel<EditprofileWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  final AuthService _authService = AuthService();

  // State field(s) for name widget.
  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;
  String? Function(BuildContext, String?)? nameTextControllerValidator;

  // State field(s) for phone widget.
  FocusNode? phoneFocusNode;
  TextEditingController? phoneTextController;
  String? Function(BuildContext, String?)? phoneTextControllerValidator;

  // Loading state
  bool isLoading = false;

  @override
  void initState(BuildContext context) {
    // Enable automatic UI updates when model changes
    updateOnChange = true;
    
    // Initialize text controllers
    nameTextController = TextEditingController();
    phoneTextController = TextEditingController();
    
    // Load user data
    loadUserData();
  }

  // Load user data from Firebase
  Future<void> loadUserData() async {
    try {
      Map<String, dynamic>? userData = await _authService.getUserProfile();
      if (userData != null) {
        nameTextController?.text = userData['username'] ?? '';
        phoneTextController?.text = userData['phone'] ?? '';
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Save profile changes (deprecated - now handled in widget directly)
  Future<bool> saveProfile() async {
    try {
      String username = nameTextController?.text.trim() ?? '';
      String phone = phoneTextController?.text.trim() ?? '';
      
      // Validate inputs
      if (username.isEmpty) {
        throw 'Please enter your full name';
      }
      
      // Update profile in Firebase
      await _authService.updateUserProfile(
        username: username,
        phone: phone.isEmpty ? null : phone,
      );
      
      return true;
    } catch (e) {
      print('Error saving profile: $e');
      throw e.toString();
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _authService.signOut();
    } catch (e) {
      print('Error signing out: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    nameFocusNode?.dispose();
    nameTextController?.dispose();
    
    phoneFocusNode?.dispose();
    phoneTextController?.dispose();
  }
}
