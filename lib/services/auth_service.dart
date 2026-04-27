import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Register
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      // Register ke Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Simpan ke firestore
      final userData = {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(uid).set(userData);

      return null; // sukses
    } on FirebaseAuthException catch (e) {

      if (e.code == 'weak-password') return 'Password terlalu lemah';
      if (e.code == 'email-already-in-use') return 'Email sudah digunakan';
      return e.message;
    } catch (e) {
      return 'Gagal menyimpan data ke database';
    }
  }

  // Login
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Email tidak ditemukan';
      if (e.code == 'wrong-password') return 'Password salah';
      if (e.code == 'invalid-credential') return 'Email atau password salah';
      return e.message;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
  

  // Get user
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}