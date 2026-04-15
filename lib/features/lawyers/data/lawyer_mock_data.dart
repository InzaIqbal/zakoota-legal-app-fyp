/// Mock data for lawyer profiles - EMPTY (Real data comes from Firestore only)
class LawyerMockData {
  static final List<LawyerProfile> lawyers = [];

  static LawyerProfile? getLawyerById(String id) {
    try {
      return lawyers.firstWhere((lawyer) => lawyer.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<LawyerProfile> searchLawyers({
    String? category,
    String? query,
    bool? verifiedOnly,
    double? minRating,
  }) {
    return [];
  }
}

class LawyerProfile {
  final String id;
  final String fullName; // Changed from 'name'
  final String professionalHeading; // Changed from 'title'
  final String location;
  final String photoUrl;
  final List<String> specializations;
  final int experienceYears; // Changed from 'experience'
  final double? rating; // Updated to double? to match DB (double or null)
  final int reviewsCount; // Changed from 'reviewCount'
  final double hourlyRate; // Updated to double match DB
  final String verificationStatus; // Changed from 'isVerified'
  final String accountStatus; // Changed from 'isActive'
  final bool isAcceptingCases;
  final List<String> education;
  final String barLicenseNo; // Changed from 'barCouncil'
  final String? bio; // Changed from 'aboutMe'
  final List<LawyerReview> reviews;

  LawyerProfile({
    required this.id,
    required this.fullName,
    required this.professionalHeading,
    required this.location,
    required this.photoUrl,
    required this.specializations,
    required this.experienceYears,
    required this.rating,
    required this.reviewsCount,
    required this.hourlyRate,
    required this.verificationStatus,
    required this.accountStatus,
    required this.isAcceptingCases,
    required this.education,
    required this.barLicenseNo,
    required this.bio,
    required this.reviews,
  });

  // Convenience getters
  bool get isVerified => verificationStatus == 'approved';
  bool get isActive => accountStatus == 'active';
  String get name => fullName;
  String get title => professionalHeading;
  String get aboutMe => bio ?? '';
  int get experience => experienceYears;
  int get casesWon => reviewsCount;
  double get ratingDouble => (rating ?? 0.0);
  double get pricePerConsultation => hourlyRate;
}

class LawyerReview {
  final String clientName;
  final double rating;
  final String comment;
  final String date;

  LawyerReview({
    required this.clientName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}
