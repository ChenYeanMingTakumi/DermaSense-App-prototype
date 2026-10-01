import '../flutter_flow/flutter_flow_model.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '../services/diagnosis_service.dart';
import 'history_widget.dart' show HistoryWidget;
import 'package:flutter/material.dart';

class HistoryModel extends FlutterFlowModel<HistoryWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();

  // Loading state
  bool isLoading = true;
  
  // History items list
  List<DiagnosisRecord> historyItems = [];
  
  // Error state
  String? errorMessage;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
  }

  /// Load diagnosis history from Firebase
  Future<void> loadHistory() async {
    try {
      isLoading = true;
      errorMessage = null;
      
      // Load diagnosis history from Firebase
      final diagnosisHistory = await DiagnosisService.getDiagnosisHistory();
      
      historyItems = diagnosisHistory;
      isLoading = false;
      
    } catch (e) {
      print('Error loading diagnosis history: $e');
      errorMessage = 'Failed to load diagnosis history';
      isLoading = false;
      historyItems = [];
    }
  }

  /// Refresh history data
  Future<void> refreshHistory() async {
    await loadHistory();
  }

  /// Navigate to diagnosis result
  Future<void> navigateToDiagnosisResult(BuildContext context, DiagnosisRecord record) async {
    try {
      // Navigate to diagnosis result page with the diagnosis record
      context.pushNamed(
        'DiagnosisResult',
        extra: {
          'diagnosisRecord': record,
        },
      );
    } catch (e) {
      print('Error navigating to diagnosis result: $e');
    }
  }
}
