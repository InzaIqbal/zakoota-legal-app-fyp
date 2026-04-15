import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

/// Messages Screen - Shows conversations list
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _chatService = ChatService();
  final _searchController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  String _searchQuery = '';
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _userRole = doc.data()?['role'];
        });
      }
    } catch (e) {
      // Handle error quietly
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Messages',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Please log in to view messages',
            style: textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Messages',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const PhosphorIcon(
                  PhosphorIconsRegular.magnifyingGlass,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.grey200),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
          // Conversations List
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: _chatService.streamConversations(_currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading conversations: ${snapshot.error}'),
                  );
                }

                final conversations = snapshot.data ?? [];
                final filteredConversations = _searchQuery.isEmpty
                    ? conversations
                    : conversations
                        .where((chat) {
                          final otherName = _userRole == 'client'
                              ? chat.lawyerName
                              : chat.clientName;
                          return otherName.toLowerCase().contains(_searchQuery) ||
                              chat.lastMessage.toLowerCase().contains(_searchQuery);
                        })
                        .toList();

                if (filteredConversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PhosphorIcon(
                          PhosphorIconsRegular.chatCircleText,
                          size: 64,
                          color: colorScheme.primary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'No conversations yet',
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: filteredConversations.length,
                  itemBuilder: (context, index) {
                    final chat = filteredConversations[index];
                    final isClient = _userRole == 'client';
                    final otherPersonName =
                        isClient ? chat.lawyerName : chat.clientName;
                    final otherPersonAvatar =
                        isClient ? chat.lawyerAvatar : chat.clientAvatar;
                    final unreadCount = chat.unreadCounts[_currentUser.uid] ?? 0;

                    return InkWell(
                      onTap: () {
                        context.push(
                          '/chat/${chat.id}',
                          extra: {
                            'clientId': chat.clientId,
                            'lawyerId': chat.lawyerId,
                            'clientName': chat.clientName,
                            'lawyerName': chat.lawyerName,
                            'clientAvatar': chat.clientAvatar,
                            'lawyerAvatar': chat.lawyerAvatar,
                            'isClient': isClient,
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: unreadCount > 0
                                ? colorScheme.primary.withValues(alpha: 0.2)
                                : AppColors.grey200,
                            width: unreadCount > 0 ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(
                                otherPersonAvatar ??
                                    'https://api.dicebear.com/7.x/avataaars/png?seed=User',
                              ),
                              backgroundColor: AppColors.grey200,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            // Name and Last Message
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    otherPersonName,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: unreadCount > 0
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: unreadCount > 0
                                          ? colorScheme.primary
                                          : AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    chat.lastMessage,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            // Unread Badge
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
