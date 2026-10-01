import '../flutter_flow/flutter_flow_model.dart';
import 'welcomepage_widget.dart' show WelcomepageWidget;
import 'package:flutter/material.dart';

class WelcomepageModel extends FlutterFlowModel<WelcomepageWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
  }
}
