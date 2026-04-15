import 'package:intl/intl.dart';
import '../models/consultation_model.dart';
import '../models/consultation_enums.dart';

/// Helper utilities for consultation operations
class ConsultationUtils {
  /// Format date and time for display
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('MMM d, yyyy \u2022 hh:mm a');
    return formatter.format(dateTime);
  }

  /// Format date only
  static String formatDate(DateTime date) {
    final formatter = DateFormat('MMM d, yyyy');
    return formatter.format(date);
  }

  /// Format time only
  static String formatTime(DateTime dateTime) {
    final formatter = DateFormat('hh:mm a');
    return formatter.format(dateTime);
  }

  /// Get remaining days until consultation
  static String getRemainingDaysText(DateTime scheduledAt) {
    final now = DateTime.now();
    final difference = scheduledAt.difference(now);
    
    if (difference.inDays > 1) {
      return 'In ${difference.inDays} days';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours} hours';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes} minutes';
    } else if (difference.isNegative) {
      return 'Past due';
    } else {
      return 'Today';
    }
  }

  /// Check if consultation is upcoming
  static bool isUpcoming(ConsultationModel consultation) {
    return consultation.scheduledAt.isAfter(DateTime.now()) &&
        (consultation.status == 'accepted' || consultation.status == 'pending');
  }

  /// Check if consultation should have been held
  static bool isPastDue(ConsultationModel consultation) {
    return consultation.scheduledAt.isBefore(DateTime.now()) &&
        consultation.status != 'completed' &&
        consultation.status != 'cancelled' &&
        consultation.status != 'rejected';
  }

  /// Check if consultation can be cancelled by user
  static bool canCancel(ConsultationModel consultation) {
    return consultation.status != 'completed' &&
        consultation.status != 'cancelled' &&
        consultation.status != 'rejected' &&
        consultation.status != 'no_show';
  }

  /// Check if consultation can be accepted
  static bool canAccept(ConsultationModel consultation, String userId) {
    return consultation.status == 'pending' && consultation.targetId == userId;
  }

  /// Check if consultation can be rejected
  static bool canReject(ConsultationModel consultation, String userId) {
    return consultation.status == 'pending' && consultation.targetId == userId;
  }

  /// Check if user can propose counter-time
  static bool canProposeCounterTime(ConsultationModel consultation, String userId) {
    return consultation.status == 'pending' &&
        consultation.targetId == userId &&
        !consultation.hasUnresolvedProposal;
  }

  /// Check if user can respond to counter-proposal
  static bool canRespondToCounterProposal(
      ConsultationModel consultation, String userId) {
    return consultation.status == 'pending' &&
        consultation.requesterId == userId &&
        consultation.hasUnresolvedProposal;
  }

  /// Check if consultation can be marked as completed
  static bool canMarkAsCompleted(ConsultationModel consultation) {
    return consultation.status == 'accepted' &&
        consultation.scheduledAt.isBefore(DateTime.now());
  }

  /// Check if consultation can be marked as no-show
  static bool canMarkAsNoShow(ConsultationModel consultation) {
    return consultation.status == 'accepted' &&
        consultation.scheduledAt.isBefore(DateTime.now()) &&
        consultation.status != 'completed';
  }

  /// Get next action text for consultation
  static String getNextActionText(ConsultationModel consultation, String userId) {
    if (consultation.status == 'pending') {
      if (consultation.targetId == userId) {
        if (consultation.hasUnresolvedProposal) {
          return 'Respond to Counter Proposal';
        }
        return 'Awaiting Your Response';
      } else {
        return 'Awaiting Their Response';
      }
    } else if (consultation.status == 'accepted') {
      if (consultation.scheduledAt.isAfter(DateTime.now())) {
        return 'Upcoming';
      } else {
        return 'Mark as Completed';
      }
    } else if (consultation.status == 'rejected') {
      return 'Rejected';
    } else if (consultation.status == 'cancelled') {
      return 'Cancelled';
    } else if (consultation.status == 'completed') {
      return 'Completed';
    } else if (consultation.status == 'no_show') {
      return 'No Show';
    }
    return 'Unknown';
  }

  /// Validate meeting details based on consultation type
  static String? validateMeetingDetails(
      ConsultationType type, String? meetingLink, String? location) {
    if (type == ConsultationType.video) {
      if (meetingLink == null || meetingLink.isEmpty) {
        return 'Meeting link is required for video consultations';
      }
      if (!_isValidUrl(meetingLink)) {
        return 'Please enter a valid meeting link';
      }
    } else {
      if (location == null || location.isEmpty) {
        return 'Location is required for in-person consultations';
      }
      if (location.length < 5) {
        return 'Please enter a valid location';
      }
    }
    return null;
  }

  /// Check if string is a valid URL
  static bool _isValidUrl(String url) {
    try {
      Uri.parse(url);
      return url.contains('http');
    } catch (e) {
      return false;
    }
  }

  /// Get summary text for consultation
  static String getSummaryText(ConsultationModel consultation) {
    final type = stringToConsultationType(consultation.type).displayName;
    final date = formatDate(consultation.scheduledAt);
    final time = formatTime(consultation.scheduledAt);
    
    return '$type • $date at $time';
  }

  /// Get duration display text
  static String getDurationText(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else if (minutes % 60 == 0) {
      return '${minutes ~/ 60}h';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
  }

  /// Check if consultation needs immediate attention
  static bool needsAttention(ConsultationModel consultation, String userId) {
    // Pending and awaiting user's response
    if (consultation.status == 'pending' && consultation.targetId == userId) {
      return true;
    }
    
    // Has unresolved counter proposal
    if (consultation.hasUnresolvedProposal && consultation.requesterId == userId) {
      return true;
    }
    
    // Past due and not completed
    if (isPastDue(consultation)) {
      return true;
    }
    
    return false;
  }
}

// Helper function
ConsultationType stringToConsultationType(String type) {
  return type.toLowerCase() == 'video'
      ? ConsultationType.video
      : ConsultationType.inPerson;
}
