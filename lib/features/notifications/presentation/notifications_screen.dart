import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Notifications Screen
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Notifications',
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Mark all read',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: user == null
          ? _buildNotLoggedInState()
          : StreamBuilder<List<AppNotification>>(
              stream: _notificationService.streamNotifications(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final notifications = snapshot.data ?? [];
                if (notifications.isEmpty) {
                  return _buildEmptyState();
                }

                final grouped = _groupNotifications(notifications);
                final today = grouped.$1;
                final earlier = grouped.$2;

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    if (today.isNotEmpty) ...[
                      Text(
                        'Today',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...today.map((notification) => _NotificationCard(
                            notification: notification,
                            onTap: () => _handleNotificationTap(notification),
                            onDismiss: () =>
                                _dismissNotification(notification.id),
                          )),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (earlier.isNotEmpty) ...[
                      Text(
                        'Earlier',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...earlier.map((notification) => _NotificationCard(
                            notification: notification,
                            onTap: () => _handleNotificationTap(notification),
                            onDismiss: () =>
                                _dismissNotification(notification.id),
                          )),
                    ],
                  ],
                );
              },
            ),
    );
  }

  Widget _buildNotLoggedInState() {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Text(
        'Please login to view notifications',
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.warning,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Could not load notifications',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.bellSlash,
            size: 80,
            color: AppColors.grey300,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No notifications',
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'You\'re all caught up!',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  (List<AppNotification>, List<AppNotification>) _groupNotifications(
    List<AppNotification> notifications,
  ) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final today = notifications
        .where((n) => n.createdAt.isAfter(todayStart))
        .toList();
    final earlier = notifications
        .where((n) => n.createdAt.isBefore(todayStart))
        .toList();
    return (today, earlier);
  }

  Future<void> _markAllAsRead() async {
    final user = _authService.currentUser;
    if (user == null) return;

    await _notificationService.markAllAsRead(user.uid);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _dismissNotification(String id) async {
    final user = _authService.currentUser;
    if (user == null) return;
    await _notificationService.dismissNotification(user.uid, id);
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    final user = _authService.currentUser;
    if (user == null) return;

    if (!notification.isRead) {
      await _notificationService.markAsRead(user.uid, notification.id);
    }
  }
}

/// Notification Card Widget
class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isRead = notification.isRead;
    final timestamp = notification.createdAt;
    final type = notification.typeKey;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: PhosphorIcon(
          PhosphorIconsRegular.trash,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onDismiss(),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color:
              isRead ? AppColors.surface : AppColors.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isRead
                ? AppColors.grey300
                : AppColors.secondary.withValues(alpha: 0.3),
            width: isRead ? 1 : 2,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: _getNotificationIcon(type),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                  ),
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(timestamp),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.all(AppSpacing.md),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'hearing':
        icon = PhosphorIconsFill.gavel;
        color = AppColors.error;
        break;
      case 'message':
        icon = PhosphorIconsFill.chatCircleText;
        color = AppColors.info;
        break;
      case 'document':
        icon = PhosphorIconsFill.fileText;
        color = AppColors.secondary;
        break;
      case 'payment':
        icon = PhosphorIconsFill.wallet;
        color = AppColors.success;
        break;
      case 'case_update':
        icon = PhosphorIconsFill.clipboard;
        color = AppColors.warning;
        break;
      case 'lawyer_assigned':
        icon = PhosphorIconsFill.userCircle;
        color = AppColors.primary;
        break;
      case 'case_filed':
        icon = PhosphorIconsFill.checkCircle;
        color = AppColors.success;
        break;
      default:
        icon = PhosphorIconsFill.bell;
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: PhosphorIcon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(timestamp);
    }
  }
}
