import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with Google
  // Returns Map with 'status' and 'role'
  Future<Map<String, dynamic>> signInWithGoogle(
      {String role = 'client'}) async {
    try {
      // 1. Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return {'status': 'cancelled'};

      // 2. Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) throw Exception('Google Sign In failed');

      // 5. Check if User Document Exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        // Strict Role Check for existing users - REMOVED for Smart Redirection
        // Now we return the actual role so UI can redirect
        final existingRole = userDoc.data()?['role'] ?? 'client';

        return {
          'status': 'dashboard',
          'role': existingRole,
        };
      } else {
        // New User -> Create Doc
        final Map<String, dynamic> userData = {
          'fullName': user.displayName ?? 'No Name',
          'email': user.email ?? '',
          'role': role,
          'walletBalance': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'photoUrl': user.photoURL ??
              'https://api.dicebear.com/7.x/avataaars/png?seed=${user.uid}',
        };

        if (role == 'lawyer') {
          userData.addAll({
            'verificationStatus': 'pending_submission',
            'accountStatus': 'active',
            'isOnline': false,
            'rating': 0.0,
            'reviewsCount': 0,
            'experienceYears': 0,
          });
          await _firestore.collection('users').doc(user.uid).set(userData);
          return {'status': 'profile_setup', 'role': 'lawyer'};
        } else {
          userData.addAll({
            'verificationStatus': 'profile_pending',
          });
          await _firestore.collection('users').doc(user.uid).set(userData);
          return {'status': 'profile_pending', 'role': 'client'};
        }
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign Up a new User (Client or Lawyer)
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'client', // Default is client, can be 'lawyer'
  }) async {
    try {
      // 1. Create Auth User
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Create Firestore Document
      if (userCredential.user != null) {
        final Map<String, dynamic> userData = {
          'fullName': fullName,
          'email': email,
          'role': role,
          'walletBalance': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'photoUrl':
              'https://api.dicebear.com/7.x/avataaars/png?seed=${userCredential.user!.uid}',
        };

        // Add specific fields for Lawyer
        if (role == 'lawyer') {
          userData.addAll({
            'verificationStatus': 'pending_submission', // Start here
            'accountStatus': 'active',
            'isOnline': false,
            'rating': 0.0,
            'reviewsCount': 0,
            'experienceYears': 0, // Will be calculated later
          });
        } else {
          // Client specific
          userData.addAll({
            'verificationStatus': 'profile_pending',
          });
        }

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign In
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get User Role
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get User Data (Public Info)
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Change Password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('User not logged in or email unavailable.');
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  // Complete Profile Setup
  Future<void> completeProfileSetup({
    required String age,
    required String address,
    required String profession,
    required String cnicNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'age': int.tryParse(age) ?? 0,
        'address': address,
        'profession': profession,
        'cnicNumber': cnicNumber,
        'verificationStatus': 'docs_pending', // Move to docs upload
        'profileSetupCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Upload Verification Documents
  Future<void> uploadVerification({
    required XFile cnicStart,
    required XFile
        cnicEnd, // Keeping param but ignoring as per user request for now
    required XFile selfie,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // 1. Upload Images to Storage
      // Use explicit paths as requested
      String cnicUrl =
          await _uploadFile(cnicStart, 'verifications/${user.uid}/cnic.jpg');
      String selfieUrl =
          await _uploadFile(selfie, 'verifications/${user.uid}/selfie.jpg');

      // 2. Update Firestore Verification Status
      // Update fields directly on the user document as requested
      await _firestore.collection('users').doc(user.uid).update({
        'verificationStatus': 'pending',
        'cnicUrl': cnicUrl,
        'selfieUrl': selfieUrl,
        'verificationSubmittedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to upload verification: $e');
    }
  }

  Future<String> _uploadFile(XFile file, String path) async {
    final ref = _storage.ref().child(path);
    // Universal upload: read as bytes and upload data
    // This works for both Web and Mobile/Desktop
    final bytes = await file.readAsBytes();
    final metadata = SettableMetadata(
      contentType: 'image/jpeg', // Assuming jpeg/png
      cacheControl: 'public,max-age=300',
    );
    final task = await ref.putData(bytes, metadata);
    return await task.ref.getDownloadURL();
  }

  // --- Lawyer Specific Methods ---

  Future<void> uploadVerificationLawyer(
      String uid, XFile file, String docType) async {
    try {
      String path = 'verifications/lawyers/$uid/$docType.jpg';
      String url = await _uploadFile(file, path);

      await _firestore.collection('users').doc(uid).update({
        'verificationDocuments.$docType': url,
      });
    } catch (e) {
      throw Exception('Failed to upload $docType: $e');
    }
  }

  Future<void> uploadProfilePhotoLawyer(String uid, XFile file) async {
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      String path = 'profile_photos/$uid/profile_$nowMs.jpg';
      String url = await _uploadFile(file, path);

      await _firestore.collection('users').doc(uid).update({
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'photoUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Keep FirebaseAuth profile photo in sync for places that read auth user.
      final user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        await user.updatePhotoURL(url);
        await user.reload();
      }
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  /// Universal profile photo upload — works for both clients and lawyers.
  Future<void> uploadProfilePhoto(String uid, XFile file) =>
      uploadProfilePhotoLawyer(uid, file);


  Future<void> submitLawyerVerification(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'verificationStatus': 'pending_approval',
        'verificationSubmittedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to submit verification: $e');
    }
  }

  // Stream of User Document for redirect logic
  Stream<DocumentSnapshot<Map<String, dynamic>>?> getUserStream() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(null);
      }
      return _firestore.collection('users').doc(user.uid).snapshots();
    });
  }

  // Helper to get current user
  User? get currentUser => _auth.currentUser;

  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Please login.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          return 'Invalid credentials. Please check your email and password.';
        default:
          return 'Authentication error: ${e.message}';
      }
    }
    return 'An unexpected error occurred: $e';
  }
}

// Extension needed for switchMap or use rxdart, 
// but implementing simple StreamBuilder approach in router might be cleaner 
// or getting a dependecy like rxdart. 
// For now, let's keep it simple and use a manual stream mapping if needed, 
// OR just use rxdart which is common in Flutter. 
// Wait, I shouldn't introduce rxdart if not already there.
// Let's rewrite getUserStream to not rely on switchMap from rxdart if it's not in pubspec.
// Checking pubspec... no rxdart.
// I will rewrite getUserStream to use standard async* if possible or just return auth changes 
// and handle doc fetch in router?
// Actually, `Stream<User?>` is enough for Auth, 
// but for the Router to know "verificationStatus", it needs the Firestore Doc.
// The best way without RxDart is slightly complex. 
// I'll add a simple stream transformer or just use a StreamController.


