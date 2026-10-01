import '/flutter_flow/flutter_flow_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/auth_service.dart';
import 'signin_widget.dart' show SigninWidget;
import 'package:flutter/material.dart';

class SigninModel extends FlutterFlowModel<SigninWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();

  // State field(s) for email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for password widget.
  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;

  @override
  void initState(BuildContext context) {
    passwordVisibility = false;
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    emailFocusNode?.dispose();
    emailTextController?.dispose();

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();
  }

  /// Additional helper methods for signin functionality
  Future<void> signIn(BuildContext context) async {
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

      // Sign in using AuthService
      final authService = AuthService();
      await authService.signInWithEmailAndPassword(
        email: emailTextController!.text.trim(),
        password: passwordTextController!.text,
      );

      // Update last sign in time
      await authService.updateLastSignIn();

      // Hide loading indicator
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in successful!'),
          backgroundColor: Colors.green,
        ),
      );

      // Always navigate to home for existing users signing in
      context.goNamed('home');

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

  /// Sign in with Google
  Future<void> signInWithGoogle(BuildContext context) async {
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

      // Sign in with Google using AuthService
      final authService = AuthService();
      final result = await authService.signInWithGoogle();

      if (result != null) {
        // Check if this was a new account creation (additionalUserInfo.isNewUser)
        bool isNewUser = result.additionalUserInfo?.isNewUser ?? false;

        // Hide loading indicator
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign in successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate based on whether this is a new user or existing user
        if (isNewUser) {
          // New user - show welcome page
          context.goNamed('welcomepage');
        } else {
          // Existing user - go directly to home
          context.goNamed('home');
        }
      } else {
        // Hide loading indicator
        Navigator.of(context).pop();
      }

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
    if (emailTextController?.text.trim().isEmpty ?? true) {
      _showErrorMessage(context, 'Please enter an email address');
      return false;
    }

    if (passwordTextController?.text.isEmpty ?? true) {
      _showErrorMessage(context, 'Please enter a password');
      return false;
    }

    // Validate email format
    if (!AuthService.isValidEmail(emailTextController!.text.trim())) {
      _showErrorMessage(context, 'Please enter a valid email address');
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
