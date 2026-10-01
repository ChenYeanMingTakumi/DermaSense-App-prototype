import '../flutter_flow/flutter_flow_model.dart';
import '../services/diagnosis_service.dart';
import 'diagnosis_result_widget.dart' show DiagnosisResultWidget;
import 'package:flutter/material.dart';
import 'dart:typed_data';

class DiagnosisResultModel extends FlutterFlowModel<DiagnosisResultWidget> {
  // Result data from AI prediction
  String? prediction;
  double? confidence;
  String? description;
  Map<String, double>? allProbabilities;
  
  // Image data
  Uint8List? resultImageBytes;
  String? imageUrl;
  
  // Diagnosis ID from Firebase
  String? diagnosisId;
  
  // Historical diagnosis data
  DiagnosisRecord? diagnosisRecord;
  bool isHistoricalDiagnosis = false;
  
  // Loading state
  bool isLoading = false;
  
  // Error state
  String? errorMessage;

  /// Set the prediction results for new diagnoses
  void setPredictionResults({
    required String prediction,
    required double confidence,
    required String description,
    required Map<String, double> allProbabilities,
    required Uint8List imageBytes,
  }) {
    this.prediction = prediction;
    this.confidence = confidence;
    this.description = description;
    this.allProbabilities = allProbabilities;
    this.resultImageBytes = imageBytes;
    this.imageUrl = null;
    this.diagnosisRecord = null;
    this.isHistoricalDiagnosis = false;
    this.errorMessage = null;
  }

  /// Set existing diagnosis record for historical diagnoses
  void setExistingDiagnosis(DiagnosisRecord record) {
    this.diagnosisRecord = record;
    this.prediction = record.diagnosisType;
    this.confidence = record.confidence;
    this.description = record.description;
    this.allProbabilities = record.allProbabilities;
    this.imageUrl = record.diagnosisImageLink;
    this.resultImageBytes = null;
    this.isHistoricalDiagnosis = true;
    this.diagnosisId = record.id;
    this.errorMessage = null;
    this.isLoading = false;
  }

  /// Set error state
  void setError(String error) {
    this.errorMessage = error;
    this.isLoading = false;
  }

  /// Set loading state
  void setLoading(bool loading) {
    this.isLoading = loading;
    if (loading) {
      this.errorMessage = null;
    }
  }

  // Diagnosis ID is managed by DiagnosisService during saving

  /// Get formatted confidence percentage
  String get confidencePercentage => 
    confidence != null ? '${(confidence! * 100).toStringAsFixed(1)}%' : '0%';

  /// Check if results are available
  bool get hasResults => prediction != null && confidence != null;

  /// Get confidence level description
  String get confidenceLevel {
    if (confidence == null) return 'Unknown';
    if (confidence! >= 0.8) return 'High';
    if (confidence! >= 0.6) return 'Medium';
    return 'Low';
  }

  /// Get confidence color based on level
  Color get confidenceColor {
    if (confidence == null) return Colors.grey;
    if (confidence! >= 0.8) return Colors.green;
    if (confidence! >= 0.6) return Colors.orange;
    return Colors.red;
  }

  /// Get formatted timestamp for historical diagnoses
  String get formattedTimestamp {
    if (diagnosisRecord != null) {
      return diagnosisRecord!.formattedTimestamp;
    }
    return '';
  }

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    // Clean up resources
    resultImageBytes = null;
    prediction = null;
    confidence = null;
    description = null;
    allProbabilities = null;
    errorMessage = null;
    diagnosisId = null;
    diagnosisRecord = null;
    imageUrl = null;
    isHistoricalDiagnosis = false;
  }
}
