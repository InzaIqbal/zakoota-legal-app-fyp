import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../notifications/services/notification_service.dart';

/// Lawyer main wrapper with bottom navigation
class LawyerMainWrapper extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const LawyerMainWrapper({super.key, required this.navigationShell});

  @override
  State<LawyerMainWrapper> createState() => _LawyerMainWrapperState();
}

class _LawyerMainWrapperState extends State<LawyerMainWrapper> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: widget.navigationShell.currentIndex,
            onTap: _onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.secondary,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(
              fontFamily: AppTextStyles.bodyFont,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: AppTextStyles.bodyFont,
              fontWeight: FontWeight.w500,
            ),
            items: [
              BottomNavigationBarItem(
                icon: PhosphorIcon(PhosphorIconsRegular.squaresFour),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: PhosphorIcon(PhosphorIconsRegular.briefcase),
                label: 'My Cases',
              ),
              BottomNavigationBarItem(
                icon: PhosphorIcon(PhosphorIconsRegular.magnifyingGlass),
                label: 'Job Board',
              ),
              BottomNavigationBarItem(
                icon: _buildMessagesIconWithBadge(),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: PhosphorIcon(PhosphorIconsRegular.user),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesIconWithBadge() {
    final user = _authService.currentUser;
    if (user == null) {
      return const PhosphorIcon(PhosphorIconsRegular.chatCircleText);
    }

    return StreamBuilder<int>(
      stream: _notificationService.streamUnreadCount(user.uid),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const PhosphorIcon(PhosphorIconsRegular.chatCircleText),
            if (unreadCount > 0)
              Positioned(
                right: -4,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
