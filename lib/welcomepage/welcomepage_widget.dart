import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '../flutter_flow/flutter_flow_widgets.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'welcomepage_model.dart';
export 'welcomepage_model.dart';

class WelcomepageWidget extends StatefulWidget {
  const WelcomepageWidget({super.key});

  @override
  State<WelcomepageWidget> createState() => _WelcomepageWidgetState();
}

class _WelcomepageWidgetState extends State<WelcomepageWidget> {
  late WelcomepageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WelcomepageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FlutterFlowTheme.of(context).primary,
                  FlutterFlowTheme.of(context).secondary,
                ],
                stops: [0.0, 1.0],
                begin: AlignmentDirectional(0.0, -1.0),
                end: AlignmentDirectional(0, 1.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Welcome Image/Icon
                Container(
                  width: 200.0,
                  height: 200.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 25.0,
                        color: Color(0x33000000),
                        offset: Offset(0.0, 15.0),
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.health_and_safety,
                    color: FlutterFlowTheme.of(context).primary,
                    size: 100.0,
                  ),
                ),
                
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 40.0, 0.0, 0.0),
                  child: Text(
                    'Welcome to DermaSense',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).headlineLarge.override(
                          fontFamily: 'Outfit',
                          color: Colors.white,
                          fontSize: 36.0,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(32.0, 24.0, 32.0, 0.0),
                  child: Text(
                    'Your AI-powered companion for skin health monitoring and early detection of skin conditions.',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).titleMedium.override(
                          fontFamily: 'Readex Pro',
                          color: Colors.white,
                          fontSize: 18.0,
                        ),
                  ),
                ),
                
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(40.0, 20.0, 40.0, 0.0),
                  child: Text(
                    'Get started by taking a photo or uploading an image for instant AI analysis.',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Readex Pro',
                          color: Colors.white70,
                          fontSize: 16.0,
                        ),
                  ),
                ),
                
                // Get Started Button
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(40.0, 50.0, 40.0, 0.0),
                  child: FFButtonWidget(
                    onPressed: () async {
                      // Mark user as having seen welcome page
                      final authService = AuthService();
                      await authService.markWelcomeAsSeen();
                      
                      // Navigate to home page
                      context.goNamed('home');
                    },
                    text: 'Get Started',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 55.0,
                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: Colors.white,
                      textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                            fontFamily: 'Readex Pro',
                            color: FlutterFlowTheme.of(context).primary,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                          ),
                      elevation: 5.0,
                      borderSide: BorderSide(
                        color: Colors.transparent,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
