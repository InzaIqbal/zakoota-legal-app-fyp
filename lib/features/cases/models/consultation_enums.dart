import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

/// Consultation status enum
enum ConsultationStatus {
  pending,
  accepted,
  rejected,
  cancelled,
  completed,
  noShow,
}

/// Consultation type enum
enum ConsultationType {
  video,
  inPerson,
}

/// Meeting platform enum
enum MeetingPlatform {
  zoom,
  googleMeet,
  teams,
  other,
}

/// Extensions for consultation enums
extension ConsultationStatusExtension on ConsultationStatus {
  String get value {
    switch (this) {
      case ConsultationStatus.pending:
        return 'pending';
      case ConsultationStatus.accepted:
        return 'accepted';
      case ConsultationStatus.rejected:
        return 'rejected';
      case ConsultationStatus.cancelled:
        return 'cancelled';
      case ConsultationStatus.completed:
        return 'completed';
      case ConsultationStatus.noShow:
        return 'no_show';
    }
  }

  String get displayName {
    switch (this) {
      case ConsultationStatus.pending:
        return 'Pending';
      case ConsultationStatus.accepted:
        return 'Accepted';
      case ConsultationStatus.rejected:
        return 'Rejected';
      case ConsultationStatus.cancelled:
        return 'Cancelled';
      case ConsultationStatus.completed:
        return 'Completed';
      case ConsultationStatus.noShow:
        return 'No Show';
    }
  }

  Color get color {
    switch (this) {
      case ConsultationStatus.pending:
        return AppColors.warning;
      case ConsultationStatus.accepted:
        return AppColors.success;
      case ConsultationStatus.rejected:
        return AppColors.error;
      case ConsultationStatus.cancelled:
        return AppColors.error;
      case ConsultationStatus.completed:
        return AppColors.success;
      case ConsultationStatus.noShow:
        return AppColors.error;
    }
  }

  IconData get icon {
    switch (this) {
      case ConsultationStatus.pending:
        return Icons.time_to_leave;
      case ConsultationStatus.accepted:
        return Icons.check_circle;
      case ConsultationStatus.rejected:
        return Icons.cancel;
      case ConsultationStatus.cancelled:
        return Icons.close;
      case ConsultationStatus.completed:
        return Icons.done_all;
      case ConsultationStatus.noShow:
        return Icons.no_meeting_room;
    }
  }
}

extension ConsultationTypeExtension on ConsultationType {
  String get value {
    switch (this) {
      case ConsultationType.video:
        return 'video';
      case ConsultationType.inPerson:
        return 'in_person';
    }
  }

  String get displayName {
    switch (this) {
      case ConsultationType.video:
        return 'Video Call';
      case ConsultationType.inPerson:
        return 'In-Person';
    }
  }

  IconData get icon {
    switch (this) {
      case ConsultationType.video:
        return Icons.videocam;
      case ConsultationType.inPerson:
        return Icons.people;
    }
  }
}

extension MeetingPlatformExtension on MeetingPlatform {
  String get value {
    switch (this) {
      case MeetingPlatform.zoom:
        return 'zoom';
      case MeetingPlatform.googleMeet:
        return 'google_meet';
      case MeetingPlatform.teams:
        return 'teams';
      case MeetingPlatform.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case MeetingPlatform.zoom:
        return 'Zoom';
      case MeetingPlatform.googleMeet:
        return 'Google Meet';
      case MeetingPlatform.teams:
        return 'Microsoft Teams';
      case MeetingPlatform.other:
        return 'Other';
    }
  }
}

/// Parse string to ConsultationStatus
ConsultationStatus stringToConsultationStatus(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return ConsultationStatus.pending;
    case 'accepted':
      return ConsultationStatus.accepted;
    case 'rejected':
      return ConsultationStatus.rejected;
    case 'cancelled':
      return ConsultationStatus.cancelled;
    case 'completed':
      return ConsultationStatus.completed;
    case 'no_show':
      return ConsultationStatus.noShow;
    default:
      return ConsultationStatus.pending;
  }
}

/// Parse string to ConsultationType
ConsultationType stringToConsultationType(String type) {
  switch (type.toLowerCase()) {
    case 'video':
      return ConsultationType.video;
    case 'in_person':
      return ConsultationType.inPerson;
    default:
      return ConsultationType.video;
  }
}

/// Parse string to MeetingPlatform
MeetingPlatform stringToMeetingPlatform(String? platform) {
  switch (platform?.toLowerCase()) {
    case 'zoom':
      return MeetingPlatform.zoom;
    case 'google_meet':
      return MeetingPlatform.googleMeet;
    case 'teams':
      return MeetingPlatform.teams;
    default:
      return MeetingPlatform.other;
  }
}
