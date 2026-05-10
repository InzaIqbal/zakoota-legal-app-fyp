import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../chat/services/chat_service.dart';

/// Main wrapper for client screens with bottom navigation bar
class ClientMainWrapper extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  static final ChatService _chatService = ChatService();
  static final AuthService _authService = AuthService();

  const ClientMainWrapper({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
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
        child: BottomNavigationBar(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.secondary,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          currentIndex: navigationShell.currentIndex,
          onTap: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          selectedLabelStyle: const TextStyle(
            fontFamily: AppTextStyles.bodyFont,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: AppTextStyles.bodyFont,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          items: [
            BottomNavigationBarItem(
              icon: PhosphorIcon(
                PhosphorIconsRegular.house,
                size: 24,
              ),
              activeIcon: PhosphorIcon(
                PhosphorIconsFill.house,
                size: 24,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: PhosphorIcon(
                PhosphorIconsRegular.briefcase,
                size: 24,
              ),
              activeIcon: PhosphorIcon(
                PhosphorIconsFill.briefcase,
                size: 24,
              ),
              label: 'My Cases',
            ),
            BottomNavigationBarItem(
              icon: _buildBadgeIcon(
                regularIcon: PhosphorIconsRegular.chatCircleText,
                fillIcon: PhosphorIconsFill.chatCircleText,
                isActive: navigationShell.currentIndex == 2,
              ),
              activeIcon: PhosphorIcon(
                PhosphorIconsFill.chatCircleText,
                size: 24,
              ),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: PhosphorIcon(
                PhosphorIconsRegular.user,
                size: 24,
              ),
              activeIcon: PhosphorIcon(
                PhosphorIconsFill.user,
                size: 24,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon({
    required PhosphorIconData regularIcon,
    required PhosphorIconData fillIcon,
    required bool isActive,
  }) {
    final user = _authService.currentUser;
    if (user == null) {
      return PhosphorIcon(isActive ? fillIcon : regularIcon, size: 24);
    }

    return StreamBuilder<int>(
      stream: _chatService.streamTotalUnreadCount(user.uid),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            PhosphorIcon(isActive ? fillIcon : regularIcon, size: 24),
            if (unreadCount > 0)
              Positioned(
                right: -4,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.rectangle,
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
