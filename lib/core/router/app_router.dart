import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/lawyer_welcome.dart';
import '../../features/auth/presentation/lawyer_signup_screen.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart'; // Import SignUpScreen
import '../../features/auth/presentation/client_profile_setup_screen.dart'; // Import ClientProfileSetupScreen
import '../../features/auth/presentation/client_verification_screen.dart'; // Import ClientVerificationScreen

import '../../features/lawyer_auth/presentation/lawyer_profile_setup_screen.dart'; // Import LawyerProfileSetupScreen
import '../../features/lawyer_auth/presentation/lawyer_verification_screen.dart'; // Import LawyerVerificationScreen
import '../../features/lawyer_auth/presentation/verification_pending_screen.dart'; // Import VerificationPendingScreen
import '../../features/lawyer_auth/presentation/verification_rejected_screen.dart'; // Import VerificationRejectedScreen

import '../../features/dashboard/presentation/client_home_screen.dart';
import '../../features/cases/presentation/my_cases_screen.dart';
import '../../features/cases/presentation/case_details_screen.dart';
import '../../features/cases/presentation/client_case_ad_details_screen.dart';
import '../../features/cases/presentation/edit_case_screen.dart';
import '../../features/cases/presentation/consultation_details_screen.dart';
import '../../features/cases/presentation/completed_cases_screen.dart';
import '../../features/cases/presentation/active_case_workspace_screen.dart';
import '../../features/cases/models/case_model.dart';
import '../../features/chat/presentation/conversations_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/chat/presentation/ai_chat_screen.dart'; // ADDED: AI Chat Screen
import '../../features/chat/models/chat_model.dart';
import '../../features/chat/services/chat_service.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/main/presentation/client_main_wrapper.dart';
import '../../features/lawyers/presentation/lawyer_search_screen.dart';
import '../../features/lawyers/presentation/lawyer_profile_screen.dart'
    as client_lawyer;
import '../../features/wallet/presentation/wallet_screen.dart';
import '../../features/wallet/presentation/withdraw_page.dart';
import '../../features/events/presentation/calendar_page.dart';
import '../../features/booking/presentation/booking_screen.dart';
import '../../features/booking/presentation/booking_summary_screen.dart';
import '../../features/cases/presentation/create_case_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/lawyers/data/lawyer_mock_data.dart';
import '../../features/lawyer_dashboard/presentation/lawyer_main_wrapper.dart';
import '../../features/lawyer_dashboard/presentation/lawyer_home_screen.dart';
import '../../features/lawyer_dashboard/presentation/lawyer_analytics_screen.dart';
import '../../features/lawyer_cases/presentation/lawyer_cases_screen.dart';
import '../../features/jobs/presentation/job_board_screen.dart';
import '../../features/jobs/presentation/job_details_screen.dart';
import '../../features/jobs/models/job_opportunity.dart';
import '../../features/lawyer_profile/presentation/lawyer_profile_screen.dart';
import '../../features/lawyer_profile/presentation/lawyer_bio_setup_screen.dart';
import '../../features/lawyer_profile/presentation/lawyer_photo_upload_screen.dart';
import '../../features/lawyer_profile/presentation/lawyer_edit_profile_screen.dart';
import '../../features/lawyer_profile/presentation/lawyer_security_password_screen.dart';
import '../../features/ads/presentation/create_lawyer_ad_screen.dart';
import '../../features/ads/presentation/manage_lawyer_ads_screen.dart';
import '../../features/ads/presentation/book_lawyer_ad_screen.dart';
import '../../features/ads/presentation/setup_workspace_screen.dart';
import '../../features/lawyer_dashboard/presentation/lawyer_availability_settings_screen.dart';

import '../../features/profile/presentation/saved_lawyers_screen.dart';
import '../../features/profile/presentation/security_settings_screen.dart';
import '../../features/profile/presentation/language_settings_screen.dart';
import '../../features/profile/presentation/help_center_screen.dart';
import '../../features/profile/presentation/terms_privacy_screen.dart';
import '../../features/documents/presentation/document_review_screen.dart';
import '../../features/articles/presentation/legal_articles_screen.dart';
import '../services/auth_service.dart'; // Import AuthService
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

// Function to create a custom refresh stream
Stream<DocumentSnapshot<Map<String, dynamic>>?> _authStream() {
  return AuthService().getUserStream();
}

/// GoRouter configuration for the app
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  refreshListenable: GoRouterRefreshStream(_authStream()),
  redirect: (context, state) async {
    final authService = AuthService();
    final user = authService.currentUser;
    final isLoggedIn = user != null;

    // Paths that don't satisfy "isLoggedIn" check (public paths)
    final isSplash = state.uri.path == '/';
    final isOnboarding = state.uri.path == '/onboarding';
    final isLogin = state.uri.path == '/login';
    final isWelcome = state.uri.path == '/welcome';
    final isSignup = state.uri.path == '/signup';
    final isLawyerWelcome = state.uri.path == '/lawyer-welcome';
    final isLawyerSignup = state.uri.path == '/lawyer-signup';

    // If not logged in, allow public paths, otherwise redirect to login
    if (!isLoggedIn) {
      if (isSplash ||
          isOnboarding ||
          isLogin ||
          isWelcome ||
          isSignup ||
          isLawyerWelcome ||
          isLawyerSignup) {
        return null; // Stick to current path
      }
      return '/login'; // Redirect to login for protected routes
    }

    // If logged in, check verification status
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        return '/login'; // Should not happen ideally
      }

      final userData = userDoc.data();
      if (userData == null) return '/login';

      final role = userData['role'];

      // --- CLIENT REDIRECTION ---
      if (role == 'client') {
        final verificationStatus = userData['verificationStatus'];

        if (verificationStatus == 'profile_pending' ||
            verificationStatus == 'none') {
          // New flow: Profile first
          if (state.uri.path != '/client-profile-setup') {
            return '/client-profile-setup';
          }
        } else if (verificationStatus == 'docs_pending') {
          // Then Docs
          if (state.uri.path != '/client-verification') {
            return '/client-verification';
          }
        } else if (verificationStatus == 'pending' ||
            verificationStatus == 'verified') {
          // Allow access
          // Prevent going back to verification or auth screens
          if (isSplash ||
              isOnboarding ||
              isLogin ||
              isSignup ||
              isWelcome ||
              state.uri.path == '/client-profile-setup' ||
              state.uri.path == '/client-verification') {
            return '/client-home';
          }
        }
      }

      // --- LAWYER REDIRECTION ---
      else if (role == 'lawyer') {
        final verificationStatus = userData['verificationStatus'];

        if (verificationStatus == 'pending_submission') {
          // Go to Profile Setup
          if (state.uri.path != '/lawyer-profile-setup') {
            return '/lawyer-profile-setup';
          }
        } else if (verificationStatus == 'pending_docs') {
          // Go to Document Verification
          if (state.uri.path != '/lawyer-verification') {
            return '/lawyer-verification';
          }
        } else if (verificationStatus == 'pending_approval') {
          // Go to Under Review
          if (state.uri.path != '/verification-pending') {
            return '/verification-pending';
          }
        } else if (verificationStatus == 'rejected') {
          // Go to Rejected
          if (state.uri.path != '/verification-rejected') {
            return '/verification-rejected';
          }
        } else if (verificationStatus == 'approved') {
          // Go to Dashboard or Public Profile Setup
          final publicProfileCompleted =
              userData['publicProfileCompleted'] == true;

          if (!publicProfileCompleted) {
            // Force Public Profile Setup
            if (state.uri.path == '/lawyer-bio-setup' ||
                state.uri.path == '/lawyer-photo-upload') {
              return null; // Allow access to setup pages
            }
            return '/lawyer-bio-setup'; // Start at Bio Setup
          } else {
            // Approved & Profile Completed -> Dashboard
            // Prevent access to auth/setup screens
            if (isSplash ||
                isOnboarding ||
                isLogin ||
                isSignup ||
                isWelcome ||
                isLawyerWelcome ||
                isLawyerSignup ||
                state.uri.path == '/lawyer-profile-setup' ||
                state.uri.path == '/lawyer-verification' ||
                state.uri.path == '/verification-pending' ||
                state.uri.path == '/lawyer-bio-setup' ||
                state.uri.path == '/lawyer-photo-upload') {
              return '/lawyer-dashboard';
            }
          }
        }
      }
    } catch (e) {
      print('Error in redirect: $e');
      return null;
    }

    return null; // No redirect needed
  },

  routes: [
    // Splash Screen (Root)
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // AI Chat Screen - ADDED
    GoRoute(
      path: '/ai-chat',
      name: 'ai-chat',
      builder: (context, state) {
        final extra = state.extra;
        String? initialMessage;
        if (extra is Map) {
          final v = extra['initialMessage'];
          if (v is String && v.trim().isNotEmpty) {
            initialMessage = v.trim();
          }
        }
        return AIChatScreen(initialMessage: initialMessage);
      },
    ),

    // Onboarding Screen
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Welcome/Role Selection Screen
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),

    // Client Sign Up Screen - NEW
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignUpScreen(),
    ),

    // Client Profile Setup Screen - NEW
    GoRoute(
      path: '/client-profile-setup',
      name: 'client-profile-setup',
      builder: (context, state) => const ClientProfileSetupScreen(),
    ),

    // Client Verification Screen - NEW
    GoRoute(
      path: '/client-verification',
      name: 'client-verification',
      builder: (context, state) => const ClientVerificationScreen(),
    ),

    // Lawyer Welcome Screen
    GoRoute(
      path: '/lawyer-welcome',
      name: 'lawyer-welcome',
      builder: (context, state) => const LawyerWelcomeScreen(),
    ),

    // Lawyer Sign Up Screen
    GoRoute(
      path: '/lawyer-signup',
      name: 'lawyer-signup',
      builder: (context, state) => const LawyerSignUpScreen(),
    ),

    // Lawyer Profile Setup Screen
    GoRoute(
      path: '/lawyer-profile-setup',
      name: 'lawyer-profile-setup',
      builder: (context, state) => const LawyerProfileSetupScreen(),
    ),

    // Lawyer Public Profile Setup (Bio) - NEW
    GoRoute(
      path: '/lawyer-bio-setup',
      name: 'lawyer-bio-setup',
      builder: (context, state) => const LawyerBioSetupScreen(),
    ),

    // Lawyer Photo Upload - NEW
    GoRoute(
      path: '/lawyer-photo-upload',
      name: 'lawyer-photo-upload',
      builder: (context, state) => const LawyerPhotoUploadScreen(),
    ),

    // Lawyer Dashboard Screen moved to shell route below

    // Lawyer Verification Screen
    GoRoute(
      path: '/lawyer-verification',
      name: 'lawyer-verification',
      builder: (context, state) => const LawyerVerificationScreen(),
    ),

    // Verification Pending Screen (Consolidated)
    GoRoute(
      path: '/verification-pending',
      name: 'verification-pending',
      builder: (context, state) => const VerificationPendingScreen(),
    ),

    // Verification Rejected Screen
    GoRoute(
      path: '/verification-rejected',
      name: 'verification-rejected',
      builder: (context, state) {
        final reason = state.extra as String?;
        return VerificationRejectedScreen(reason: reason);
      },
    ),

    // Job Details Screen
    GoRoute(
      path: '/job-details/:jobId',
      name: 'job-details',
      builder: (context, state) {
        final job = state.extra;
        if (job is! JobOpportunity) {
          return const JobBoardScreen();
        }
        return JobDetailsScreen(job: job);
      },
    ),

    // Login Screen
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) {
        // Extract role from query parameters
        final role = state.uri.queryParameters['role'] ?? 'client';
        return LoginScreen(role: role);
      },
    ),

    // Lawyer Search Screen
    GoRoute(
      path: '/lawyer-search',
      name: 'lawyer-search',
      builder: (context, state) {
        final category = state.uri.queryParameters['category'];
        return LawyerSearchScreen(category: category);
      },
    ),

    // Lawyer Profile Screen
    GoRoute(
      path: '/lawyer-profile/:lawyerId',
      name: 'client-lawyer-profile',
      builder: (context, state) {
        final lawyerId = state.pathParameters['lawyerId']!;
        return client_lawyer.LawyerProfileScreen(lawyerId: lawyerId);
      },
    ),

    // Wallet Screen
    GoRoute(
      path: '/wallet',
      name: 'wallet',
      builder: (context, state) => const WalletScreen(),
    ),

    GoRoute(
      path: '/withdraw',
      name: 'withdraw',
      builder: (context, state) => const WithdrawPage(),
    ),

    GoRoute(
      path: '/calendar',
      name: 'calendar',
      builder: (context, state) => const CalendarPage(),
    ),

    // Booking Screen
    GoRoute(
      path: '/booking/:lawyerId',
      name: 'booking',
      builder: (context, state) {
        final lawyerId = state.pathParameters['lawyerId']!;
        return BookingScreen(lawyerId: lawyerId);
      },
    ),

    // Booking Summary Screen
    GoRoute(
      path: '/booking-summary',
      name: 'booking-summary',
      builder: (context, state) {
        final extra = state.extra;
        if (extra == null || extra is! Map<String, dynamic>) {
          return const LawyerSearchScreen();
        }
        final bookingData = Map<String, dynamic>.from(extra);
        // Add lawyer name to booking data
        final lawyerId = bookingData['lawyerId'] as String;
        final lawyer = LawyerMockData.getLawyerById(lawyerId);
        bookingData['lawyerName'] = lawyer?.name ?? 'Unknown';

        return BookingSummaryScreen(bookingData: bookingData);
      },
    ),

    // Create Case Screen
    GoRoute(
      path: '/create-case',
      name: 'create-case',
      builder: (context, state) => const CreateCaseScreen(),
    ),

    // Document Review Screen
    GoRoute(
      path: '/document-review',
      name: 'document-review',
      builder: (context, state) => const DocumentReviewScreen(),
    ),
    
    // My Documents Screen

    // Legal Articles Screen
    GoRoute(
      path: '/legal-articles',
      name: 'legal-articles',
      builder: (context, state) => const LegalArticlesScreen(),
    ),

    // Chat Screen
    GoRoute(
      path: '/chat/:conversationId',
      name: 'chat',
      builder: (context, state) {
        final conversationId = state.pathParameters['conversationId']!;
        final extra = state.extra;
        
        if (extra == null || extra is! Map<String, dynamic>) {
          // If extra is missing (e.g. from notification or browser refresh),
          // fallback to conversation list instead of crashing
          return const ConversationsScreen();
        }
        
        return ChatScreen(
          conversationId: conversationId,
          lawyerData: extra,
        );
      },
    ),

    // Direct Chat Route (Find or Create by IDs)
    GoRoute(
      path: '/chat/direct/:partnerId',
      name: 'chat-direct',
      builder: (context, state) {
        final partnerId = state.pathParameters['partnerId']!;
        final extra = state.extra as Map<String, dynamic>?;

        return FutureBuilder<ChatModel>(
          future: ChatService().getOrCreateChat(
            clientId: extra?['clientId'] ?? '',
            lawyerId: extra?['lawyerId'] ?? partnerId,
            clientName: extra?['clientName'] ?? 'Client',
            lawyerName: extra?['lawyerName'] ?? 'Lawyer',
            clientAvatar: extra?['clientAvatar'],
            lawyerAvatar: extra?['lawyerAvatar'],
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Scaffold(
                appBar: AppBar(title: const Text('Chat')),
                body: Center(
                    child: Text('Error starting chat: ${snapshot.error}')),
              );
            }

            final chat = snapshot.data!;
            return ChatScreen(
              conversationId: chat.id,
              lawyerData: {
                'lawyerId': chat.lawyerId,
                'lawyerName': chat.lawyerName,
                'lawyerAvatar': chat.lawyerAvatar,
                'clientId': chat.clientId,
                'clientName': chat.clientName,
                'clientAvatar': chat.clientAvatar,
                'isOnline': true,
              },
            );
          },
        );
      },
    ),

    // Edit Profile Screen
    GoRoute(
      path: '/edit-profile',
      name: 'edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),

    // Lawyer Edit Profile Screen
    GoRoute(
      path: '/lawyer-edit-profile',
      name: 'lawyer-edit-profile',
      builder: (context, state) => const LawyerEditProfileScreen(),
    ),

    // Case Details Screen
    GoRoute(
      path: '/case-details/:caseId',
      name: 'case-details',
      builder: (context, state) {
        final caseId = state.pathParameters['caseId']!;
        final tab = state.uri.queryParameters['tab'];
        final initialTabIndex =
            tab == 'documents' ? 2 : (tab == 'timeline' ? 1 : 0);
        return CaseDetailsScreen(
          caseId: caseId,
          initialTabIndex: initialTabIndex,
        );
      },
    ),

    // Consultation Details Screen
    GoRoute(
      path: '/consultation-details/:caseId/:consultationId',
      name: 'consultation-details',
      builder: (context, state) {
        final caseId = state.pathParameters['caseId']!;
        final consultationId = state.pathParameters['consultationId']!;
        return ConsultationDetailsScreen(
          caseId: caseId,
          consultationId: consultationId,
        );
      },
    ),

    // Client Case Ad Details Screen
    GoRoute(
      path: '/case-ad-details',
      name: 'case-ad-details',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! CaseModel) return const MyCasesScreen();
        return ClientCaseAdDetailsScreen(caseModel: extra);
      },
    ),

    // Edit Case Screen
    GoRoute(
      path: '/edit-case',
      name: 'edit-case',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! CaseModel) return const MyCasesScreen();
        return EditCaseScreen(caseModel: extra);
      },
    ),

    // Notifications Screen
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/completed-cases',
      name: 'completed-cases',
      builder: (context, state) => const CompletedCasesScreen(),
    ),
    GoRoute(
      path: '/lawyer-create-ad',
      name: 'lawyer-create-ad',
      builder: (context, state) => const CreateLawyerAdScreen(),
    ),
    GoRoute(
      path: '/lawyer-edit-ad/:adId',
      name: 'lawyer-edit-ad',
      builder: (context, state) {
        final adId = state.pathParameters['adId'] ?? '';
        return CreateLawyerAdScreen(adId: adId);
      },
    ),
    GoRoute(
      path: '/lawyer-manage-ads',
      name: 'lawyer-manage-ads',
      builder: (context, state) => const ManageLawyerAdsScreen(),
    ),
    GoRoute(
      path: '/lawyer-availability-settings',
      name: 'lawyer-availability-settings',
      builder: (context, state) => const LawyerAvailabilitySettingsScreen(),
    ),
    GoRoute(
      path: '/book-lawyer-ad/:adId',
      name: 'book-lawyer-ad',
      builder: (context, state) {
        final adId = state.pathParameters['adId'] ?? '';
        return BookLawyerAdScreen(adId: adId);
      },
    ),
    GoRoute(
      path: '/setup-workspace/:bookingId',
      name: 'setup-workspace',
      builder: (context, state) {
        final bookingId = state.pathParameters['bookingId'] ?? '';
        final extra = state.extra;
        final formData = extra is Map<String, dynamic> ? extra : null;
        return SetupWorkspaceScreen(
          bookingId: bookingId,
          formData: formData,
        );
      },
    ),
    GoRoute(
      path: '/case-workspace',
      name: 'case-workspace',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is Map<String, dynamic> &&
            extra['caseModel'] is CaseModel &&
            extra['isClient'] is bool) {
          return ActiveCaseWorkspaceScreen(
            caseModel: extra['caseModel'] as CaseModel,
            isClient: extra['isClient'] as bool,
          );
        }

        final caseId = state.uri.queryParameters['caseId'];
        final isClientRaw = state.uri.queryParameters['isClient'];
        final isClient = isClientRaw == 'true';
        final tab = state.uri.queryParameters['tab'];
        final initialTabIndex = tab == 'events'
          ? 3
          : tab == 'milestones'
            ? 4
            : tab == 'invoices'
              ? 5
              : tab == 'consultations'
                ? 1
                : tab == 'files'
                  ? 2
                  : 0;

        if (caseId == null || caseId.isEmpty) {
          return _WorkspaceRedirectFallback(isClient: isClient);
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('cases').doc(caseId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final doc = snapshot.data;
            if (doc == null || !doc.exists || doc.data() == null) {
              return _WorkspaceRedirectFallback(isClient: isClient);
            }

            return ActiveCaseWorkspaceScreen(
              caseModel: CaseModel.fromMap(doc.data()!, doc.id),
              isClient: isClient,
              initialTabIndex: initialTabIndex,
            );
          },
        );
      },
    ),

    // Saved Lawyers Screen
    GoRoute(
      path: '/saved-lawyers',
      name: 'saved-lawyers',
      builder: (context, state) => const SavedLawyersScreen(),
    ),

    // Profile Settings Routes
    GoRoute(
      path: '/security-settings',
      builder: (context, state) => const SecuritySettingsScreen(),
    ),
    GoRoute(
      path: '/language-settings',
      builder: (context, state) => const LanguageSettingsScreen(),
    ),
    GoRoute(
      path: '/help-center',
      builder: (context, state) => const HelpCenterScreen(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsPrivacyScreen(),
    ),
    GoRoute(
      path: '/lawyer-security-password',
      builder: (context, state) => const LawyerSecurityPasswordScreen(),
    ),

    // Lawyer Main Shell with Bottom Navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return LawyerMainWrapper(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/lawyer-dashboard',
              name: 'lawyer-dashboard',
              builder: (context, state) => const LawyerHomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/lawyer-cases',
              name: 'lawyer-cases',
              builder: (context, state) => const LawyerCasesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/lawyer-job-board',
              name: 'lawyer-job-board',
              builder: (context, state) => const JobBoardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/lawyer-messages',
              name: 'lawyer-messages',
              builder: (context, state) => const ConversationsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/lawyer-profile',
              name: 'lawyer-portal-profile',
              builder: (context, state) => const LawyerProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // Lawyer Analytics (outside shell - no bottom bar)
    GoRoute(
      path: '/lawyer-dashboard/lawyer-analytics',
      name: 'lawyer-analytics',
      builder: (context, state) => const LawyerAnalyticsScreen(),
    ),

    // Client Main Shell with Bottom Navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ClientMainWrapper(navigationShell: navigationShell);
      },
      branches: [
        // Branch 1: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/client-home',
              name: 'client-home',
              builder: (context, state) => const ClientHomeScreen(),
            ),
          ],
        ),

        // Branch 2: My Cases
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/client-cases',
              name: 'client-cases',
              builder: (context, state) => const MyCasesScreen(),
            ),
          ],
        ),

        // Branch 3: Messages
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/client-messages',
              name: 'client-messages',
              builder: (context, state) => const ConversationsScreen(),
            ),
          ],
        ),

        // Branch 4: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/client-profile',
              name: 'client-profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],

  // Error handling
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);

// Helper class for GoRouter refresh stream
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _WorkspaceRedirectFallback extends StatefulWidget {
  final bool isClient;

  const _WorkspaceRedirectFallback({required this.isClient});

  @override
  State<_WorkspaceRedirectFallback> createState() =>
      _WorkspaceRedirectFallbackState();
}

class _WorkspaceRedirectFallbackState extends State<_WorkspaceRedirectFallback> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(widget.isClient ? '/client-cases' : '/lawyer-cases');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
