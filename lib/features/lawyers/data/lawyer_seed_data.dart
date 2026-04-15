/// Lawyer Seed Data - Use this to populate Firestore
/// Simple email/password pairs for testing

class LawyerSeedData {
  static const List<Map<String, dynamic>> lawyers = [
    {
      'email': 'sarah@zakoota.com',
      'password': 'Sarah@123',
      'name': 'Adv. Sarah Ahmed',
      'title': 'Senior Advocate',
      'location': 'Lahore High Court',
      'photoUrl': 'https://i.pravatar.cc/150?img=5',
      'specializations': ['Criminal Law', 'Constitutional Law'],
      'experience': 12,
      'casesWon': 145,
      'rating': 4.9,
      'reviewCount': 120,
      'pricePerConsultation': 3000,
      'isVerified': true,
      'isActive': true,
      'education': ['LLB, Punjab University', 'LLM, Oxford University'],
      'barCouncil': 'Lahore High Court Bar Association',
      'aboutMe': 'Senior criminal law specialist with 12 years of experience.',
    },
    {
      'email': 'hassan@zakoota.com',
      'password': 'Hassan@123',
      'name': 'Adv. Hassan Ali',
      'title': 'Advocate High Court',
      'location': 'Islamabad',
      'photoUrl': 'https://i.pravatar.cc/150?img=12',
      'specializations': ['Property Law', 'Corporate Law'],
      'experience': 8,
      'casesWon': 98,
      'rating': 4.7,
      'reviewCount': 85,
      'pricePerConsultation': 2500,
      'isVerified': true,
      'isActive': true,
      'education': ['LLB, Quaid-e-Azam University'],
      'barCouncil': 'Islamabad Bar Association',
      'aboutMe': 'Property and corporate law specialist.',
    },
    {
      'email': 'fatima@zakoota.com',
      'password': 'Fatima@123',
      'name': 'Adv. Fatima Khan',
      'title': 'Senior Advocate',
      'location': 'Karachi High Court',
      'photoUrl': 'https://i.pravatar.cc/150?img=9',
      'specializations': ['Family Law', 'Divorce & Custody'],
      'experience': 10,
      'casesWon': 112,
      'rating': 4.8,
      'reviewCount': 95,
      'pricePerConsultation': 2800,
      'isVerified': true,
      'isActive': true,
      'education': ['LLB, Karachi University'],
      'barCouncil': 'Karachi Bar Association',
      'aboutMe': 'Family law and women rights advocate.',
    },
    {
      'email': 'usman@zakoota.com',
      'password': 'Usman@123',
      'name': 'Adv. Usman Malik',
      'title': 'Corporate Lawyer',
      'location': 'Lahore',
      'photoUrl': 'https://i.pravatar.cc/150?img=15',
      'specializations': ['Startup Law', 'Business Formation'],
      'experience': 6,
      'casesWon': 67,
      'rating': 4.6,
      'reviewCount': 52,
      'pricePerConsultation': 3500,
      'isVerified': true,
      'isActive': true,
      'education': ['LLB, LUMS'],
      'barCouncil': 'Punjab Bar Council',
      'aboutMe': 'Startup and business law expert.',
    },
    {
      'email': 'zainab@zakoota.com',
      'password': 'Zainab@123',
      'name': 'Adv. Zainab Siddiqui',
      'title': 'Civil Rights Advocate',
      'location': 'Supreme Court',
      'photoUrl': 'https://i.pravatar.cc/150?img=20',
      'specializations': ['Civil Law', 'Public Interest'],
      'experience': 15,
      'casesWon': 178,
      'rating': 4.9,
      'reviewCount': 142,
      'pricePerConsultation': 4000,
      'isVerified': true,
      'isActive': true,
      'education': ['LLB, Lahore University', 'LLM, Cambridge'],
      'barCouncil': 'Supreme Court Bar Association',
      'aboutMe': 'Civil rights and constitutional law expert.',
    },
    {
      'email': 'imran@zakoota.com',
      'password': 'Imran@123',
      'name': 'Adv. Imran Haider',
      'title': 'Tax & Finance Lawyer',
      'location': 'Islamabad',
      'photoUrl': 'https://i.pravatar.cc/150?img=33',
      'specializations': ['Tax Law', 'Banking Law'],
      'experience': 9,
      'casesWon': 89,
      'rating': 4.5,
      'reviewCount': 68,
      'pricePerConsultation': 3200,
      'isVerified': true,
      'isActive': true,
      'education': ['LLB, IIU'],
      'barCouncil': 'Islamabad Bar Association',
      'aboutMe': 'Tax and banking law specialist.',
    },
  ];

  /// Copy this and paste in Firebase Console > Firestore > lawyers collection
  /// Or use the populateLawyers() function below programmatically
  static void printJSON() {
    print('=== PASTE THIS IN FIRESTORE CONSOLE ===\n');
    for (var lawyer in lawyers) {
      final docId = lawyer['email']!.split('@')[0];
      final docData = {...lawyer};
      docData.remove('email');
      docData.remove('password');
      docData['reviews'] = [];
      print('Document ID: $docId');
      print('Data: ${docData.toString()}\n');
    }
  }
}

/// Quick Reference Email & Password
/// 
/// sarah@zakoota.com - Sarah@123
/// hassan@zakoota.com - Hassan@123
/// fatima@zakoota.com - Fatima@123
/// usman@zakoota.com - Usman@123
/// zainab@zakoota.com - Zainab@123
/// imran@zakoota.com - Imran@123
