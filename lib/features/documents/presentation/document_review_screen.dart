import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../cases/models/file_model.dart';
import '../../cases/models/case_model.dart';

class DocumentItem {
  final String id;
  final String fileName;
  final String fileUrl;
  final DateTime uploadedAt;
  final int fileSize;
  final String source; // 'workspace' or 'attachment'

  DocumentItem({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.uploadedAt,
    required this.fileSize,
    required this.source,
  });
}

class CaseDocumentGroup {
  final CaseModel caseData;
  final List<DocumentItem> documents;

  CaseDocumentGroup(this.caseData, this.documents);
}

class DocumentFetchResult {
  final String role;
  final List<DocumentItem> verificationDocs;
  final List<CaseDocumentGroup> caseGroups;

  DocumentFetchResult({
    required this.role,
    required this.verificationDocs,
    required this.caseGroups,
  });
}

class DocumentReviewScreen extends StatefulWidget {
  const DocumentReviewScreen({super.key});

  @override
  State<DocumentReviewScreen> createState() => _DocumentReviewScreenState();
}

class _DocumentReviewScreenState extends State<DocumentReviewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  
  String _searchQuery = '';
  int _selectedFilterDays = 0; // 0 = All Time, 7 = Last 7 days, 30 = Last 30 days

  Future<DocumentFetchResult> _fetchDocuments() async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // 1. Get User Role and Data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final role = userData['role'] ?? 'client';

      final List<DocumentItem> verificationDocs = [];
      
      // 2. Extract Verification Docs (Lawyer only)
      if (role == 'lawyer') {
        // From fields
        if (userData['cnicUrl'] != null) {
          verificationDocs.add(DocumentItem(
            id: 'verification_cnic',
            fileName: 'CNIC / Identity Proof',
            fileUrl: userData['cnicUrl'],
            uploadedAt: (userData['verificationSubmittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            fileSize: 0,
            source: 'verification',
          ));
        }
        if (userData['selfieUrl'] != null) {
          verificationDocs.add(DocumentItem(
            id: 'verification_selfie',
            fileName: 'Selfie Verification',
            fileUrl: userData['selfieUrl'],
            uploadedAt: (userData['verificationSubmittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            fileSize: 0,
            source: 'verification',
          ));
        }
        // From verificationDocuments map
        final Map<String, dynamic>? vDocs = userData['verificationDocuments'] as Map<String, dynamic>?;
        if (vDocs != null) {
          vDocs.forEach((key, value) {
            verificationDocs.add(DocumentItem(
              id: 'verification_$key',
              fileName: key[0].toUpperCase() + key.substring(1),
              fileUrl: value.toString(),
              uploadedAt: DateTime.now(), // Estimate or use submission time
              fileSize: 0,
              source: 'verification',
            ));
          });
        }
      }

      // 3. Query cases
      final QuerySnapshot clientCases = await _firestore.collection('cases').where('clientId', isEqualTo: user.uid).get();
      final QuerySnapshot lawyerCases = await _firestore.collection('cases').where('acceptedLawyerId', isEqualTo: user.uid).get();
      
      final Map<String, DocumentSnapshot> uniqueCaseDocs = {};
      for (var doc in clientCases.docs) {
        uniqueCaseDocs[doc.id] = doc;
      }
      for (var doc in lawyerCases.docs) {
        uniqueCaseDocs[doc.id] = doc;
      }

      final List<CaseDocumentGroup> groups = [];

      for (var caseDoc in uniqueCaseDocs.values) {
        try {
          final caseData = caseDoc.data() as Map<String, dynamic>;
          final caseModel = CaseModel.fromMap(caseData, caseDoc.id);

          final List<DocumentItem> caseDocuments = [];

          // A. Extract Initial Attachments (CLIENT ONLY)
          if (role == 'client') {
            for (var attachment in caseModel.attachments) {
              caseDocuments.add(DocumentItem(
                id: 'attachment_${attachment.fileUrl}',
                fileName: attachment.title,
                fileUrl: attachment.fileUrl,
                uploadedAt: caseModel.createdAt,
                fileSize: 0, 
                source: 'attachment',
              ));
            }
          }

          // B. Fetch Workspace Files (Filtered by Uploader)
          final filesSnapshot = await _firestore.collection('cases').doc(caseDoc.id).collection('files').get();
          for (var fileDoc in filesSnapshot.docs) {
            try {
              final fileData = fileDoc.data();
              final file = FileModel.fromMap(fileData, fileDoc.id);
              
              // ONLY show if current user is the uploader
              if (file.uploaderId == user.uid) {
                caseDocuments.add(DocumentItem(
                  id: file.id,
                  fileName: file.fileName,
                  fileUrl: file.fileUrl,
                  uploadedAt: file.uploadedAt,
                  fileSize: file.fileSize,
                  source: 'workspace',
                ));
              }
            } catch (e) {
              debugPrint('Error parsing file: $e');
            }
          }

          if (caseDocuments.isNotEmpty) {
            caseDocuments.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
            groups.add(CaseDocumentGroup(caseModel, caseDocuments));
          }

        } catch (e) {
          debugPrint('Error processing case document group: $e');
        }
      }

      groups.sort((a, b) {
         final aLatest = a.documents.first.uploadedAt;
         final bLatest = b.documents.first.uploadedAt;
         return bLatest.compareTo(aLatest);
      });

      return DocumentFetchResult(
        role: role,
        verificationDocs: verificationDocs,
        caseGroups: groups,
      );
    } catch (e) {
      debugPrint('Error fetching documents: $e');
      rethrow;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return 'Unknown Size';
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return '🖼';
      case 'xls':
      case 'xlsx':
      case 'csv':
        return '📊';
      default:
        return '📎';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My Documents',
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header with Search and Filters
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search documents...',
                    prefixIcon: const PhosphorIcon(PhosphorIconsRegular.magnifyingGlass),
                    filled: true,
                    fillColor: AppColors.grey200,
                    contentPadding: const EdgeInsets.all(AppSpacing.sm),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _buildFilterChip('All Time', 0),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Last 7 Days', 7),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Last 30 Days', 30),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: FutureBuilder<DocumentFetchResult>(
              future: _fetchDocuments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const PhosphorIcon(
                          PhosphorIconsRegular.warning,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Error loading documents',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          snapshot.error.toString(),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final result = snapshot.data!;
                final allGroups = result.caseGroups;
                final verificationDocs = result.verificationDocs;
                
                // Apply synchronous local filtering to Case Groups
                final List<CaseDocumentGroup> filteredGroups = [];
                final now = DateTime.now();

                for (var group in allGroups) {
                  final List<DocumentItem> filteredDocs = group.documents.where((doc) {
                    // Date filter
                    if (_selectedFilterDays > 0) {
                      final diff = now.difference(doc.uploadedAt).inDays;
                      if (diff > _selectedFilterDays) return false;
                    }
                    // Search filter
                    if (_searchQuery.isNotEmpty) {
                      final lowerSearch = _searchQuery.toLowerCase();
                      if (!doc.fileName.toLowerCase().contains(lowerSearch)) return false;
                    }
                    return true;
                  }).toList();

                  if (filteredDocs.isNotEmpty) {
                    filteredGroups.add(CaseDocumentGroup(group.caseData, filteredDocs));
                  }
                }

                // Apply synchronous local filtering to Verification Docs
                final List<DocumentItem> filteredVerificationDocs = verificationDocs.where((doc) {
                  if (_searchQuery.isNotEmpty) {
                    final lowerSearch = _searchQuery.toLowerCase();
                    if (!doc.fileName.toLowerCase().contains(lowerSearch)) return false;
                  }
                  return true;
                }).toList();

                if (filteredGroups.isEmpty && filteredVerificationDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const PhosphorIcon(
                            PhosphorIconsRegular.file,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          allGroups.isEmpty ? 'No Documents Yet' : 'No Documents Found',
                          style: textTheme.headlineSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          allGroups.isEmpty 
                              ? 'Documents you upload to cases will appear here'
                              : 'Try adjusting your search or filters.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (allGroups.isEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/create-case'),
                            icon: const PhosphorIcon(PhosphorIconsRegular.plus),
                            label: const Text('Post a Case'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    if (filteredVerificationDocs.isNotEmpty)
                      _buildVerificationCard(filteredVerificationDocs),
                    ...filteredGroups.map((group) => _buildCaseDocumentCard(group)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int days) {
    final isSelected = _selectedFilterDays == days;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilterDays = days;
          });
        }
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: AppColors.grey200,
      side: BorderSide.none,
    );
  }

  Widget _buildCaseDocumentCard(CaseDocumentGroup group) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.grey300),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Case Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                topRight: Radius.circular(AppRadius.md),
              ),
              border: Border(bottom: BorderSide(color: AppColors.grey200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.caseData.title,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Case ID: ${group.caseData.caseId.substring(0, 8).toUpperCase()}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${group.documents.length} Docs',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // List of Document Files
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.documents.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.grey200),
            itemBuilder: (context, idx) {
              final file = group.documents[idx];
              
              return _buildDocumentListTile(file);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(List<DocumentItem> docs) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.secondary, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                topRight: Radius.circular(AppRadius.md),
              ),
              border: const Border(bottom: BorderSide(color: AppColors.secondary)),
            ),
            child: Row(
              children: [
                const PhosphorIcon(PhosphorIconsFill.sealCheck, color: AppColors.secondary, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Identity & Verification',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${docs.length} Docs',
                  style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Docs
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.grey200),
            itemBuilder: (context, idx) => _buildDocumentListTile(docs[idx]),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentListTile(DocumentItem file) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final dateFormat = DateFormat('MMM d, yyyy');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Center(
          child: Text(
            _getFileIcon(file.fileName),
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              file.fileName,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (file.source == 'attachment') ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Initial',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _formatFileSize(file.fileSize),
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            Container(width: 1, height: 10, color: AppColors.grey300),
            Text(
              dateFormat.format(file.uploadedAt),
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      trailing: PopupMenuButton(
        icon: const PhosphorIcon(PhosphorIconsRegular.dotsThreeVertical, size: 20),
        itemBuilder: (context) => [
          PopupMenuItem(
            child: const Row(
              children: [
                PhosphorIcon(PhosphorIconsRegular.download, size: 18, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
                Text('Download'),
              ],
            ),
            onTap: () async {
              await launchUrl(
                Uri.parse(file.fileUrl),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
          PopupMenuItem(
            child: const Row(
              children: [
                PhosphorIcon(PhosphorIconsRegular.eye, size: 18, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
                Text('View'),
              ],
            ),
            onTap: () async {
              await launchUrl(
                Uri.parse(file.fileUrl),
                mode: LaunchMode.platformDefault,
              );
            },
          ),
        ],
      ),
    );
  }
}
