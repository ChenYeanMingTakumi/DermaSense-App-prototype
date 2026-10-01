import '../flutter_flow/flutter_flow_icon_button.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '../services/ai_service.dart';
import '../services/diagnosis_service.dart';
import 'package:flutter/material.dart';
import 'diagnosis_result_model.dart';
import 'dart:typed_data';
export 'diagnosis_result_model.dart';

/// Create a page where I can upload a picture from my device or take a
/// picture from my camera to detect skin diagnosis
///
class DiagnosisResultWidget extends StatefulWidget {
  const DiagnosisResultWidget({
    super.key,
    this.imageBytes,
    this.diagnosisRecord,
  });

  final Uint8List? imageBytes;
  final DiagnosisRecord? diagnosisRecord;

  static String routeName = 'DiagnosisResult';
  static String routePath = '/diagnosisResult';

  @override
  State<DiagnosisResultWidget> createState() => _DiagnosisResultWidgetState();
}

class _DiagnosisResultWidgetState extends State<DiagnosisResultWidget> {
  late DiagnosisResultModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DiagnosisResultModel());
    
    // Run prediction when page loads or load existing diagnosis
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDiagnosis();
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _initializeDiagnosis() async {
    // Get navigation arguments
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final diagnosisRecord = widget.diagnosisRecord ?? args?['diagnosisRecord'] as DiagnosisRecord?;
    final imageBytes = widget.imageBytes ?? args?['imageBytes'] as Uint8List?;
    
    // If we have a diagnosis record, load it
    if (diagnosisRecord != null) {
      _loadExistingDiagnosis(diagnosisRecord);
    }
    // If we have image bytes, run new prediction
    else if (imageBytes != null) {
      await _runPrediction(imageBytes);
    }
    // No data provided
    else {
      _model.setError('No image data provided');
      setState(() {});
    }
  }

  void _loadExistingDiagnosis(DiagnosisRecord diagnosisRecord) {
    _model.setExistingDiagnosis(diagnosisRecord);
    setState(() {});
  }

  Future<void> _runPrediction(Uint8List imageBytes) async {
    _model.setLoading(true);
    setState(() {});

    try {
      // Load AI model and run prediction
      await AIService.loadModel();
      final results = await AIService.predictSkinCondition(imageBytes);
      
      _model.setPredictionResults(
        prediction: results['prediction'],
        confidence: results['confidence'],
        description: results['description'],
        allProbabilities: results['all_probabilities'],
        imageBytes: imageBytes,
      );
      
      // Note: Diagnosis is already saved in diagnosis_scan_model.dart
      // No need to save again here to avoid duplicates
      print('Diagnosis analysis completed successfully');
      
      _model.setLoading(false);
      setState(() {});
    } catch (e) {
      _model.setError('Error analyzing image: $e');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            'Diagnosis Results',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 22.0,
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Image Display Container
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 24.0, 0.0),
                  child: Container(
                    width: double.infinity,
                    height: 300.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 2.0,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_model.resultImageBytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.memory(
                                _model.resultImageBytes!,
                                width: 250.0,
                                height: 250.0,
                                fit: BoxFit.cover,
                              ),
                            )
                          else if (_model.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                _model.imageUrl!,
                                width: 250.0,
                                height: 250.0,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 250.0,
                                    height: 250.0,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: FlutterFlowTheme.of(context).primary,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 250.0,
                                    height: 250.0,
                                    color: FlutterFlowTheme.of(context).alternate,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported,
                                          color: FlutterFlowTheme.of(context).secondaryText,
                                          size: 48.0,
                                        ),
                                        SizedBox(height: 8.0),
                                        Text(
                                          'Failed to load image',
                                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                            fontFamily: 'Readex Pro',
                                            color: FlutterFlowTheme.of(context).secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Icon(
                              Icons.image_outlined,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 80.0,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Results Container
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 24.0, 24.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Loading State
                          if (_model.isLoading) ...[
                            Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    color: FlutterFlowTheme.of(context).primary,
                                  ),
                                  SizedBox(height: 16.0),
                                  Text(
                                    'Analyzing your image...',
                                    style: FlutterFlowTheme.of(context).bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ]
                          // Error State
                          else if (_model.errorMessage != null) ...[
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 48.0,
                                  ),
                                  SizedBox(height: 16.0),
                                  Text(
                                    'Error',
                                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                                      fontFamily: 'Outfit',
                                      color: Colors.red,
                                    ),
                                  ),
                                  SizedBox(height: 8.0),
                                  Text(
                                    _model.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: FlutterFlowTheme.of(context).bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ]
                          // Results State
                          else if (_model.hasResults) ...[
                            // Timestamp for historical diagnoses
                            if (_model.isHistoricalDiagnosis) ...[
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).accent4,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: FlutterFlowTheme.of(context).primary,
                                      size: 20.0,
                                    ),
                                    SizedBox(width: 8.0),
                                    Text(
                                      'Diagnosed on ${_model.formattedTimestamp}',
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                        fontFamily: 'Readex Pro',
                                        color: FlutterFlowTheme.of(context).primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16.0),
                            ],
                            
                            // Prediction Result
                            Text(
                              'Diagnosis Result',
                              style: FlutterFlowTheme.of(context).headlineSmall.override(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 16.0),
                            
                            // Prediction Card
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).accent1,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _model.prediction!,
                                            style: FlutterFlowTheme.of(context).titleLarge.override(
                                              fontFamily: 'Outfit',
                                              color: FlutterFlowTheme.of(context).primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                          decoration: BoxDecoration(
                                            color: _model.confidenceColor,
                                            borderRadius: BorderRadius.circular(20.0),
                                          ),
                                          child: Text(
                                            '${_model.confidencePercentage} ${_model.confidenceLevel}',
                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                              fontFamily: 'Readex Pro',
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12.0),
                                    Text(
                                      'Confidence: ${_model.confidencePercentage}',
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                        fontFamily: 'Readex Pro',
                                        color: FlutterFlowTheme.of(context).secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            SizedBox(height: 24.0),
                            
                            // Description
                            Text(
                              'Description',
                              style: FlutterFlowTheme.of(context).titleMedium.override(
                                fontFamily: 'Readex Pro',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              _model.description!,
                                                             style: FlutterFlowTheme.of(context).bodyMedium.override(
                                 fontFamily: 'Readex Pro',
                               ),
                            ),
                            
                            SizedBox(height: 24.0),
                            
                            // Disclaimer
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Color(0xFFFFF3CD),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: Color(0xFFFFE69C),
                                  width: 1.0,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_outlined,
                                      color: Color(0xFF856404),
                                      size: 24.0,
                                    ),
                                    SizedBox(width: 12.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Medical Disclaimer',
                                            style: FlutterFlowTheme.of(context).titleSmall.override(
                                              fontFamily: 'Readex Pro',
                                              color: Color(0xFF856404),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 4.0),
                                          Text(
                                            'This AI analysis is for informational purposes only and should not replace professional medical advice. Please consult a qualified dermatologist for accurate diagnosis and treatment.',
                                                                                         style: FlutterFlowTheme.of(context).bodySmall.override(
                                               fontFamily: 'Readex Pro',
                                               color: Color(0xFF856404),
                                             ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]
                          else ...[
                            Text(
                              'No results available',
                              style: FlutterFlowTheme.of(context).bodyMedium,
                            ),
                          ],
                        ],
                      ),
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
