import '../flutter_flow/flutter_flow_icon_button.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'back_icon_model.dart';
export 'back_icon_model.dart';

/// Can you generate a Back Button on my AppBar's top left?
class BackIconWidget extends StatefulWidget {
  const BackIconWidget({super.key});

  @override
  State<BackIconWidget> createState() => _BackIconWidgetState();
}

class _BackIconWidgetState extends State<BackIconWidget> {
  late BackIconModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BackIconModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: FlutterFlowIconButton(
        borderColor: Colors.transparent,
        borderRadius: 8.0,
        borderWidth: 1.0,
        buttonSize: 40.0,
        icon: Icon(
          Icons.arrow_back_rounded,
          color: FlutterFlowTheme.of(context).primaryText,
          size: 24.0,
        ),
        onPressed: () {
          print('IconButton pressed ...');
        },
      ),
    );
  }
}
