import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/file_model.dart';
import 'package:uuid/uuid.dart';

class FileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Upload a file and save its metadata
  Future<FileModel> uploadFile({
    required String caseId,
    required String uploaderId,
    required File file,
    required String fileName,
  }) async {
    final String fileId = _uuid.v4();
    final int fileSize = await file.length();
    
    // Create reference in Storage: cases/{caseId}/{fileId}_{fileName}
    final String storagePath = 'cases/$caseId/${fileId}_$fileName';
    final Reference ref = _storage.ref().child(storagePath);
    
    // Upload file
    final UploadTask uploadTask = ref.putFile(file);
    final TaskSnapshot snapshot = await uploadTask;
    
    // Get download URL
    final String downloadUrl = await snapshot.ref.getDownloadURL();
    
    // Create model
    final fileModel = FileModel(
      id: fileId,
      caseId: caseId,
      uploaderId: uploaderId,
      fileName: fileName,
      fileUrl: downloadUrl,
      fileSize: fileSize,
      uploadedAt: DateTime.now(),
    );
    
    // Save metadata to Firestore
    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('files')
        .doc(fileId)
        .set(fileModel.toMap());
        
    return fileModel;
  }

  // Update file name
  Future<void> updateFileName(String caseId, String fileId, String newName) async {
    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('files')
        .doc(fileId)
        .update({'fileName': newName});
  }

  // Get file count for a user in a case
  Future<int> getUserFileCount(String caseId, String userId) async {
    final snapshot = await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('files')
        .where('uploaderId', isEqualTo: userId)
        .get();
    return snapshot.docs.length;
  }

  // Stream files for a specific case
  Stream<List<FileModel>> streamFilesForCase(String caseId) {
    return _firestore
        .collection('cases')
        .doc(caseId)
        .collection('files')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FileModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Delete a file
  Future<void> deleteFile(String caseId, FileModel file) async {
    // 1. Delete from Storage
    try {
      final String storagePath = 'cases/$caseId/${file.id}_${file.fileName}';
      final Reference ref = _storage.ref().child(storagePath);
      await ref.delete();
    } catch (e) {
      // It might already be deleted or URL is different, ignore storage error
      print('Warning: Failed to delete from storage: $e');
    }
    
    // 2. Delete from Firestore
    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('files')
        .doc(file.id)
        .delete();
  }
}
