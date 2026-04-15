import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>
    with SingleTickerProviderStateMixin {
  final _chatService = ChatService();
  final _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  String? _userRole;
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    if (_currentUser == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _userRole = doc.data()?['role'];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const Scaffold(body: Center(child: Text('Please login')));

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Messages',
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Zing AI Assistant',
            icon: const PhosphorIcon(PhosphorIconsRegular.sparkle, color: Colors.white),
            onPressed: () => context.push('/ai-chat'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search conversations...',
                      hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
                      prefixIcon: PhosphorIcon(PhosphorIconsRegular.magnifyingGlass, color: AppColors.textLight),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    ),
                  ),
                ),
              ),
              Container(
                color: AppColors.primary,
                child: TabBar(
                  controller: _tabController,
                  onTap: (_) => setState(() {}),
                  indicatorColor: AppColors.secondary,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                  tabs: const [Tab(text: 'All Chats'), Tab(text: 'Unread')],
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: _chatService.streamConversations(_currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(textTheme);
          }

          var chats = snapshot.data!;

          // Apply filters
          if (_searchQuery.isNotEmpty) {
            chats = chats.where((chat) {
              final otherName = _userRole == 'client' ? chat.lawyerName : chat.clientName;
              return otherName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  chat.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();
          }

          if (_tabController.index == 1) {
            chats = chats.where((chat) => (chat.unreadCounts[_currentUser.uid] ?? 0) > 0).toList();
          }

          if (chats.isEmpty) return _buildEmptyState(textTheme);

          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: chats.length,
            itemBuilder: (context, index) => _ConversationTile(
              chat: chats[index],
              userRole: _userRole ?? 'client',
              currentUserId: _currentUser.uid,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(PhosphorIconsRegular.chatCircle, size: 64, color: AppColors.textLight),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No messages yet',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              _userRole == 'lawyer' 
                ? 'Wait for clients to message you. Lawyers cannot initiate chats.'
                : 'Start a conversation from a Lawyer\'s profile.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatModel chat;
  final String userRole;
  final String currentUserId;

  const _ConversationTile({
    required this.chat,
    required this.userRole,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isClient = userRole == 'client';
    final otherName = isClient ? chat.lawyerName : chat.clientName;
    final otherAvatar = isClient ? chat.lawyerAvatar : chat.clientAvatar;
    final unreadCount = chat.unreadCounts[currentUserId] ?? 0;

    return InkWell(
      onTap: () {
        context.push(
          '/chat/${chat.id}',
          extra: {
            'lawyerName': chat.lawyerName,
            'lawyerId': chat.lawyerId,
            'clientName': chat.clientName,
            'clientId': chat.clientId,
            'isOnline': true,
            'lawyerAvatar': chat.lawyerAvatar,
            'clientAvatar': chat.clientAvatar,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.grey300.withValues(alpha: 0.3))),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.grey300,
              backgroundImage: otherAvatar != null ? NetworkImage(otherAvatar) : null,
              child: otherAvatar == null ? Text(otherName[0]) : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(otherName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(_formatTime(chat.lastMessageTime), style: textTheme.bodySmall?.copyWith(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          style: textTheme.bodyMedium?.copyWith(
                            color: unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                          child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${time.day}/${time.month}';
  }
}

