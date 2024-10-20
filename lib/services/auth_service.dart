import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'log_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '56606291217-sunsbtrgodth18heacgsgcs3u6hh7156.apps.googleusercontent.com',
  );

  AuthService() {
    LogService.info("AuthService constructor called");
    _setAuthPersistence();
  }

  Future<void> _setAuthPersistence() async {
    try {
      LogService.info("Setting Firebase Auth persistence to LOCAL");
      await _auth.setPersistence(Persistence.LOCAL);
      LogService.info("Firebase Auth persistence successfully set to LOCAL");
    } catch (e, stackTrace) {
      LogService.error("Error setting auth persistence", e, stackTrace);
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      LogService.info("Attempting Google Sign-In");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        LogService.warning("Google Sign-In canceled by user");
        return null;
      }
      LogService.info(
          "Google Sign-In successful. Fetching authentication details.");
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      LogService.info("Authentication details obtained");
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      LogService.info("Auth credentials created");
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      LogService.info("Signed in with credential");
      User? user = userCredential.user;
      if (user != null) {
        LogService.info("User signed in: ${user.displayName}, ${user.email}");
        return user;
      } else {
        LogService.warning("User is null after sign-in");
        return null;
      }
    } catch (e, stackTrace) {
      LogService.error("Error during Google Sign-In", e, stackTrace);
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      LogService.info("Signing out user");
      await _auth.signOut();
      LogService.info("Firebase Auth sign out successful");
      await _googleSignIn.signOut();
      LogService.info("Google Sign-In sign out successful");
      LogService.info("User signed out successfully");
    } catch (e, stackTrace) {
      LogService.error("Error during sign out", e, stackTrace);
    }
  }

  User? getCurrentUser() {
    LogService.info("Retrieving current user");
    User? user = _auth.currentUser;
    if (user != null) {
      LogService.info("Current user: ${user.displayName}, ${user.email}");
    } else {
      LogService.info("No user currently signed in");
    }
    return user;
  }
}
