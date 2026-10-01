import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// DiagnosisService handles Firebase Storage and Firestore operations for diagnosis data
/// 
/// Firestore Structure:
/// Users/{userId}/diagnosis/{diagnosisId}
/// - timeCreated: DateTime (when diagnosis was created)
/// - diagnosisType: String (the detected skin condition)
/// - diagnosisImageLink: String (Firebase Storage download URL)
/// - Additional fields: confidence, description, allProbabilities, imagePath
class DiagnosisService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Ensure user document exists in Firestore before creating subcollections
  static Future<void> _ensureUserDocumentExists(String userId) async {
    try {
      final DocumentReference userRef = _firestore.collection('Users').doc(userId);
      final DocumentSnapshot userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        // Create basic user document if it doesn't exist
        final User? currentUser = _auth.currentUser;
        await userRef.set({
          'uid': userId,
          'email': currentUser?.email ?? '',
          'username': currentUser?.displayName ?? 'User',
          'phone': currentUser?.phoneNumber ?? '',
          'hasSeenWelcome': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSignIn': FieldValue.serverTimestamp(),
        });
        print('Created user document for: $userId');
      }
    } catch (e) {
      print('Error ensuring user document exists: $e');
      // Don't throw - allow diagnosis to continue even if user doc creation fails
    }
  }

  /// Save diagnosis result to Firebase (Storage + Firestore)
  static Future<String> saveDiagnosisResult({
    required Uint8List imageBytes,
    required String prediction,
    required double confidence,
    required String description,
    required Map<String, double> allProbabilities,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Ensure user document exists before creating diagnosis subcollection
      await _ensureUserDocumentExists(currentUser.uid);

      // Generate unique filename for the image
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filename = 'diagnosis_${currentUser.uid}_$timestamp.jpg';
      final String imagePath = 'diagnosis_images/${currentUser.uid}/$filename';

      // Upload image to Firebase Storage
      final Reference storageRef = _storage.ref().child(imagePath);
      final UploadTask uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': currentUser.uid,
            'prediction': prediction,
            'confidence': confidence.toString(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Save diagnosis record to user's diagnosis subcollection
      // Note: Firestore automatically creates the 'diagnosis' subcollection if it doesn't exist
      final DocumentReference diagnosisRef = await _firestore
          .collection('Users')
          .doc(currentUser.uid)
          .collection('diagnosis')
          .add({
        'timeCreated': FieldValue.serverTimestamp(),
        'diagnosisType': prediction,
        'diagnosisImageLink': downloadUrl,
        // Additional fields for compatibility
        'confidence': confidence,
        'description': description,
        'allProbabilities': allProbabilities,
        'imagePath': imagePath,
        // Metadata for tracking
        'userId': currentUser.uid,
        'analysisVersion': '1.0',
      });

      return diagnosisRef.id;
    } catch (e) {
      print('Error saving diagnosis result: $e');
      throw Exception('Failed to save diagnosis result: $e');
    }
  }

  /// Get diagnosis history for current user
  static Future<List<DiagnosisRecord>> getDiagnosisHistory() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final QuerySnapshot querySnapshot = await _firestore
          .collection('Users')
          .doc(currentUser.uid)
          .collection('diagnosis')
          .orderBy('timeCreated', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return DiagnosisRecord.fromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      print('Error fetching diagnosis history: $e');
      throw Exception('Failed to fetch diagnosis history: $e');
    }
  }

  /// Get specific diagnosis record by ID
  static Future<DiagnosisRecord?> getDiagnosisById(String diagnosisId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final DocumentSnapshot doc = await _firestore
          .collection('Users')
          .doc(currentUser.uid)
          .collection('diagnosis')
          .doc(diagnosisId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return DiagnosisRecord.fromFirestore(doc.id, data);
    } catch (e) {
      print('Error fetching diagnosis: $e');
      throw Exception('Failed to fetch diagnosis: $e');
    }
  }

  /// Delete diagnosis record and associated image
  static Future<void> deleteDiagnosis(String diagnosisId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get diagnosis record first
      final DocumentSnapshot doc = await _firestore
          .collection('Users')
          .doc(currentUser.uid)
          .collection('diagnosis')
          .doc(diagnosisId)
          .get();

      if (!doc.exists) {
        throw Exception('Diagnosis record not found');
      }

      final data = doc.data() as Map<String, dynamic>;

      // Delete image from Storage if path exists
      if (data['imagePath'] != null) {
        try {
          await _storage.ref().child(data['imagePath']).delete();
        } catch (e) {
          print('Warning: Could not delete image from storage: $e');
        }
      }

      // Delete Firestore document
      await _firestore
          .collection('Users')
          .doc(currentUser.uid)
          .collection('diagnosis')
          .doc(diagnosisId)
          .delete();
    } catch (e) {
      print('Error deleting diagnosis: $e');
      throw Exception('Failed to delete diagnosis: $e');
    }
  }

  /// Get risk level based on prediction and confidence
  static String getRiskLevel(String prediction, double confidence) {
    // High-risk conditions
    if (['Melanoma', 'Measles', 'Chicken Pox'].contains(prediction)) {
      return 'High Risk';
    }
    
    // Medium-risk conditions
    if (['Acne', 'Eczema', 'Shingles'].contains(prediction)) {
      return 'Medium Risk';
    }
    
    // Low-risk conditions (based on confidence)
    if (confidence >= 0.7) {
      return 'Low Risk';
    } else if (confidence >= 0.5) {
      return 'Medium Risk';
    } else {
      return 'Uncertain';
    }
  }

  /// Get risk color based on risk level
  static String getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'High Risk':
        return 'error';
      case 'Medium Risk':
        return 'warning';
      case 'Low Risk':
        return 'success';
      default:
        return 'info';
    }
  }

  /// Get total diagnosis count for current user
  static Future<int> getDiagnosisCount() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return 0;
      }

      final QuerySnapshot querySnapshot = await _firestore
          .collection('Users')
          .doc(currentUser.uid)
          .collection('diagnosis')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting diagnosis count: $e');
      return 0;
    }
  }

  /// Check if user has any diagnosis records
  static Future<bool> hasAnyDiagnosis() async {
    final count = await getDiagnosisCount();
    return count > 0;
  }

  /// Remove duplicate diagnosis records based on timestamp and diagnosis type
  static Future<int> removeDuplicateDiagnoses() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No authenticated user for duplicate removal');
        return 0;
      }

      final QuerySnapshot querySnapshot = await _firestore
          .collection('Users')
          .doc(currentUser.uid)
          .collection('diagnosis')
          .orderBy('timeCreated', descending: true)
          .get();

      Map<String, List<QueryDocumentSnapshot>> groupedByTypeAndTime = {};
      
      // Group documents by diagnosis type and timestamp (rounded to minute)
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final diagnosisType = data['diagnosisType'] ?? '';
        final timeCreated = (data['timeCreated'] as Timestamp?)?.toDate();
        
        if (timeCreated != null) {
          // Create a key based on type and time (rounded to minute to catch near-duplicates)
          final timeKey = '${timeCreated.year}-${timeCreated.month}-${timeCreated.day}-${timeCreated.hour}-${timeCreated.minute}';
          final groupKey = '$diagnosisType-$timeKey';
          
          if (!groupedByTypeAndTime.containsKey(groupKey)) {
            groupedByTypeAndTime[groupKey] = [];
          }
          groupedByTypeAndTime[groupKey]!.add(doc);
        }
      }

      int duplicatesRemoved = 0;
      
      // Remove duplicates (keep the first one, remove the rest)
      for (var group in groupedByTypeAndTime.values) {
        if (group.length > 1) {
          // Sort by timeCreated and keep the first one
          group.sort((a, b) {
            final timeA = ((a.data() as Map<String, dynamic>)['timeCreated'] as Timestamp).toDate();
            final timeB = ((b.data() as Map<String, dynamic>)['timeCreated'] as Timestamp).toDate();
            return timeA.compareTo(timeB);
          });
          
          // Remove all except the first one
          for (int i = 1; i < group.length; i++) {
            await group[i].reference.delete();
            duplicatesRemoved++;
            print('Removed duplicate diagnosis: ${group[i].id}');
          }
        }
      }

      print('Removed $duplicatesRemoved duplicate diagnosis records');
      return duplicatesRemoved;
    } catch (e) {
      print('Error removing duplicate diagnoses: $e');
      return 0;
    }
  }

  /// Test method to verify diagnosis subcollection creation
  static Future<bool> testDiagnosisCreation() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('Test failed: No authenticated user');
        return false;
      }

      print('Testing diagnosis creation for user: ${currentUser.uid}');
      
      // Check if user document exists
      final DocumentSnapshot userDoc = await _firestore
          .collection('Users')
          .doc(currentUser.uid)
          .get();
      
      print('User document exists: ${userDoc.exists}');
      
      // Check if diagnosis subcollection exists
      final QuerySnapshot diagnosisQuery = await _firestore
          .collection('Users')
          .doc(currentUser.uid)
          .collection('diagnosis')
          .limit(1)
          .get();
      
      print('Diagnosis subcollection exists: ${diagnosisQuery.docs.isNotEmpty}');
      print('Total diagnosis count: ${diagnosisQuery.docs.length}');
      
      return true;
    } catch (e) {
      print('Test error: $e');
      return false;
    }
  }
}

/// Data model for diagnosis records
class DiagnosisRecord {
  final String id;
  final DateTime timeCreated;
  final String diagnosisType;
  final String diagnosisImageLink;
  // Additional fields for compatibility
  final double confidence;
  final String description;
  final Map<String, double> allProbabilities;
  final String? imagePath;

  DiagnosisRecord({
    required this.id,
    required this.timeCreated,
    required this.diagnosisType,
    required this.diagnosisImageLink,
    required this.confidence,
    required this.description,
    required this.allProbabilities,
    this.imagePath,
  });

  factory DiagnosisRecord.fromFirestore(String id, Map<String, dynamic> data) {
    // Handle timestamp conversion with proper timezone handling
    DateTime timeCreated;
    if (data['timeCreated'] is Timestamp) {
      timeCreated = (data['timeCreated'] as Timestamp).toDate();
    } else {
      print('Warning: timeCreated is not a Timestamp: ${data['timeCreated']}');
      timeCreated = DateTime.now();
    }
    
    return DiagnosisRecord(
      id: id,
      timeCreated: timeCreated,
      diagnosisType: data['diagnosisType'] ?? '',
      diagnosisImageLink: data['diagnosisImageLink'] ?? '',
      confidence: (data['confidence'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      allProbabilities: Map<String, double>.from(data['allProbabilities'] ?? {}),
      imagePath: data['imagePath'],
    );
  }

  /// Get formatted timestamp string
  String get formattedTimestamp {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final month = months[timeCreated.month - 1];
    final day = timeCreated.day.toString(); // No padding for day
    final year = timeCreated.year;
    
    // Convert to 12-hour format properly
    int displayHour = timeCreated.hour;
    String ampm;
    
    if (displayHour == 0) {
      displayHour = 12; // 12 AM
      ampm = 'AM';
    } else if (displayHour < 12) {
      ampm = 'AM';
    } else if (displayHour == 12) {
      ampm = 'PM'; // 12 PM
    } else {
      displayHour = displayHour - 12;
      ampm = 'PM';
    }
    
    final minute = timeCreated.minute.toString().padLeft(2, '0');
    
    return '$month $day, $year · $displayHour:$minute $ampm';
  }

  /// Get risk level for this diagnosis
  String get riskLevel => DiagnosisService.getRiskLevel(diagnosisType, confidence);

  /// Get risk color for this diagnosis
  String get riskColor => DiagnosisService.getRiskColor(riskLevel);

  // Backward compatibility getters
  String get prediction => diagnosisType;
  String get imageUrl => diagnosisImageLink;
  DateTime get timestamp => timeCreated;
} 