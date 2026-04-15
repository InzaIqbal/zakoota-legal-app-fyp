import 'package:cloud_firestore/cloud_firestore.dart';

class FileModel {
  final String id;
  final String caseId;
  final String uploaderId;
  final String fileName;
  final String fileUrl;
  final int fileSize; // bytes
  final DateTime uploadedAt;

  FileModel({
    required this.id,
    required this.caseId,
    required this.uploaderId,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'caseId': caseId,
      'uploaderId': uploaderId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  factory FileModel.fromMap(Map<String, dynamic> map, String id) {
    return FileModel(
      id: id,
      caseId: map['caseId'] ?? '',
      uploaderId: map['uploaderId'] ?? '',
      fileName: map['fileName'] ?? 'Unknown File',
      fileUrl: map['fileUrl'] ?? '',
      fileSize: map['fileSize']?.toInt() ?? 0,
      uploadedAt: map['uploadedAt'] != null 
          ? (map['uploadedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }
}
