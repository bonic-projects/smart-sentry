import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_sentry/models/appuser.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> registerUser(UserModel user) async {
    try {
      // Create the user in Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );
      String uid = userCredential.user?.uid ?? '';
      user.id = uid;
      // Save the user data to Firestore with the Firebase-generated UID
      await _firestore.collection('users').doc(uid).set(user.toMap());

      // Explicitly return the UserCredential
      return userCredential;
    } catch (e) {
      // Handle the exception and rethrow it to notify the caller
      throw Exception("Failed to register user: $e");
    }
  }

  Future<void> loginUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  bool get hasLoggedInUser => _auth.currentUser != null;

  Future<void> logoutUser() async {
    await _auth.signOut();
  }
}
