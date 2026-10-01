import '/flutter_flow/flutter_flow_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/auth_service.dart';
import 'changepassword_widget.dart' show ChangepasswordWidget;
import 'package:flutter/material.dart';

class ChangepasswordModel extends FlutterFlowModel<ChangepasswordWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();

  // State field(s) for currentPassword widget.
  FocusNode? currentPasswordFocusNode;
  TextEditingController? currentPasswordTextController;
  late bool currentPasswordVisibility;
  String? Function(BuildContext, String?)? currentPasswordTextControllerValidator;
  // State field(s) for newPassword widget.
  FocusNode? newPasswordFocusNode;
  TextEditingController? newPasswordTextController;
  late bool newPasswordVisibility;
  String? Function(BuildContext, String?)? newPasswordTextControllerValidator;
  // State field(s) for confirmPassword widget.
  FocusNode? confirmPasswordFocusNode;
  TextEditingController? confirmPasswordTextController;
  late bool confirmPasswordVisibility;
  String? Function(BuildContext, String?)? confirmPasswordTextControllerValidator;

  @override
  void initState(BuildContext context) {
    currentPasswordVisibility = false;
    newPasswordVisibility = false;
    confirmPasswordVisibility = false;
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    currentPasswordFocusNode?.dispose();
    currentPasswordTextController?.dispose();

    newPasswordFocusNode?.dispose();
    newPasswordTextController?.dispose();

    confirmPasswordFocusNode?.dispose();
    confirmPasswordTextController?.dispose();
  }

  /// Change password functionality
  Future<void> changePassword(BuildContext context) async {
    // Validate all fields
    if (!_validateFields(context)) {
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Change password using AuthService
      final authService = AuthService();
      await authService.changePassword(
        currentPassword: currentPasswordTextController!.text,
        newPassword: newPasswordTextController!.text,
      );

      // Hide loading indicator
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to home page
      context.goNamed('home');

    } catch (e) {
      // Hide loading indicator if showing
      Navigator.of(context).pop();

      // Check if the error is related to wrong current password
      String errorMessage = e.toString();
      if (errorMessage.contains('wrong-password') || 
          errorMessage.contains('Authentication failed') ||
          errorMessage.contains('Invalid credentials')) {
        errorMessage = 'Wrong password, try again';
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Validate all form fields
  bool _validateFields(BuildContext context) {
    // Check if any fields are empty
    if (_areFieldsEmpty()) {
      _showErrorMessage(context, 'Please fill in all fields');
      return false;
    }

    // Check if passwords match
    if (!_doPasswordsMatch()) {
      _showErrorMessage(context, 'Please ensure passwords are same');
      return false;
    }

    // Check password strength
    if (!_isPasswordStrong()) {
      _showErrorMessage(context, 'New password must be at least 6 characters long');
      return false;
    }

    return true;
  }

  /// Check if any fields are empty
  bool _areFieldsEmpty() {
    return (currentPasswordTextController?.text.isEmpty ?? true) ||
           (newPasswordTextController?.text.isEmpty ?? true) ||
           (confirmPasswordTextController?.text.isEmpty ?? true);
  }

  /// Check if new password and confirm password match
  bool _doPasswordsMatch() {
    return newPasswordTextController?.text == confirmPasswordTextController?.text;
  }

  /// Check if password meets minimum requirements
  bool _isPasswordStrong() {
    return (newPasswordTextController?.text.length ?? 0) >= 6;
  }

  /// Show error message
  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
