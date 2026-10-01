import '/flutter_flow/flutter_flow_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/auth_service.dart';
import 'signup_widget.dart' show SignupWidget;
import 'package:flutter/material.dart';

class SignupModel extends FlutterFlowModel<SignupWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();

  // State field(s) for username widget.
  FocusNode? usernameFocusNode;
  TextEditingController? usernameTextController;
  String? Function(BuildContext, String?)? usernameTextControllerValidator;
  // State field(s) for email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for password widget.
  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;
  // State field(s) for confirmPassword widget.
  FocusNode? confirmPasswordFocusNode;
  TextEditingController? confirmPasswordTextController;
  late bool confirmPasswordVisibility;
  String? Function(BuildContext, String?)? confirmPasswordTextControllerValidator;

  @override
  void initState(BuildContext context) {
    passwordVisibility = false;
    confirmPasswordVisibility = false;
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    usernameFocusNode?.dispose();
    usernameTextController?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();

    confirmPasswordFocusNode?.dispose();
    confirmPasswordTextController?.dispose();
  }

  /// Additional helper methods for signup functionality
  Future<void> signUp(BuildContext context) async {
    // Validate form fields
    if (!_validateForm(context)) {
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

      // Create account using AuthService
      final authService = AuthService();
      await authService.signUpWithEmailAndPassword(
        email: emailTextController!.text.trim(),
        password: passwordTextController!.text,
        username: usernameTextController!.text.trim(),
      );

      // Hide loading indicator
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to welcome page for first-time users
      context.goNamed('welcomepage');

    } catch (e) {
      // Hide loading indicator if showing
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Validate form fields
  bool _validateForm(BuildContext context) {
    // Check if all fields are filled
    if (usernameTextController?.text.trim().isEmpty ?? true) {
      _showErrorMessage(context, 'Please enter a username');
      return false;
    }

    if (emailTextController?.text.trim().isEmpty ?? true) {
      _showErrorMessage(context, 'Please enter an email address');
      return false;
    }

    if (passwordTextController?.text.isEmpty ?? true) {
      _showErrorMessage(context, 'Please enter a password');
      return false;
    }

    if (confirmPasswordTextController?.text.isEmpty ?? true) {
      _showErrorMessage(context, 'Please confirm your password');
      return false;
    }

    // Validate email format
    if (!AuthService.isValidEmail(emailTextController!.text.trim())) {
      _showErrorMessage(context, 'Please enter a valid email address');
      return false;
    }

    // Validate password strength
    if (!AuthService.isValidPassword(passwordTextController!.text)) {
      _showErrorMessage(context, 'Password must be at least 6 characters long');
      return false;
    }

    // Check if passwords match
    if (passwordTextController!.text != confirmPasswordTextController!.text) {
      _showErrorMessage(context, 'Passwords do not match');
      return false;
    }

    // Validate username length
    if (usernameTextController!.text.trim().length < 2) {
      _showErrorMessage(context, 'Username must be at least 2 characters long');
      return false;
    }

    return true;
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
