import '/flutter_flow/flutter_flow_util.dart';
import 'diagnosis_scan_widget.dart' show DiagnosisScanWidget;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';
import '../services/diagnosis_service.dart';

class DiagnosisScanModel extends FlutterFlowModel<DiagnosisScanWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  // Selected image file
  FFUploadedFile uploadedLocalFile = FFUploadedFile(bytes: Uint8List.fromList([]));
  
  // Analysis state
  bool isAnalyzing = false;
  String? analysisError;

  @override
  void initState(BuildContext context) {
    // Initialize AI model when page loads
    _initializeAIModel();
  }

  @override
  void dispose() {
    unfocusNode.dispose();
  }

  /// Initialize AI model
  Future<void> _initializeAIModel() async {
    try {
      await AIService.loadModel();
      print('AI model loaded successfully');
    } catch (e) {
      print('Error loading AI model: $e');
      analysisError = 'Failed to load AI model';
    }
  }

  /// Select image from camera
  Future<void> selectImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        uploadedLocalFile = FFUploadedFile(
          name: image.name,
          bytes: bytes,
        );
        
        // Clear any previous analysis error
        analysisError = null;
        
        print('Image selected from camera: ${image.name}');
      }
    } catch (e) {
      print('Error selecting image from camera: $e');
      analysisError = 'Failed to capture image from camera';
    }
  }

  /// Select image from gallery
  Future<void> selectImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        uploadedLocalFile = FFUploadedFile(
          name: image.name,
          bytes: bytes,
        );
        
        // Clear any previous analysis error
        analysisError = null;
        
        print('Image selected from gallery: ${image.name}');
      }
    } catch (e) {
      print('Error selecting image from gallery: $e');
      analysisError = 'Failed to select image from gallery';
    }
  }

  /// Analyze the selected image using AI
  Future<void> analyzeImage(BuildContext context) async {
    if (uploadedLocalFile.bytes == null || uploadedLocalFile.bytes!.isEmpty) {
      analysisError = 'Please select an image first';
      return;
    }

    try {
      isAnalyzing = true;
      analysisError = null;

      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(width: 16),
                Text('Analyzing image...'),
              ],
            ),
            duration: Duration(seconds: 10),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // Perform AI analysis
      final result = await AIService.predictSkinCondition(uploadedLocalFile.bytes!);
      
      // Save diagnosis result to Firebase
      await DiagnosisService.saveDiagnosisResult(
        imageBytes: uploadedLocalFile.bytes!,
        prediction: result['prediction'],
        confidence: result['confidence'],
        description: result['description'],
        allProbabilities: Map<String, double>.from(result['all_probabilities']),
      );

      isAnalyzing = false;

      // Hide loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
        // Navigate to diagnosis result page with the image bytes
        context.pushNamed(
          'DiagnosisResult',
          extra: {
            'imageBytes': uploadedLocalFile.bytes!,
          },
        );
      }
    } catch (e) {
      isAnalyzing = false;
      analysisError = 'Analysis failed: ${e.toString()}';
      
      print('Error during image analysis: $e');
      
      // Hide loading indicator and show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Clear selected image
  void clearImage() {
    uploadedLocalFile = FFUploadedFile(bytes: Uint8List.fromList([]));
    analysisError = null;
  }

  /// Check if image is selected
  bool get hasImage => uploadedLocalFile.bytes?.isNotEmpty ?? false;
}
