// services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'log_service.dart';
import 'database_service.dart';
import '../models/user_profile.dart';
import 'ip_service.dart';
import 'geolocation_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_database/firebase_database.dart'; // For ServerValue.timestamp

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  final DatabaseService _databaseService;
  final IPService _ipService;
  final GeolocationService _geolocationService;

  AuthService({
    required DatabaseService databaseService,
    required IPService ipService,
    required GeolocationService geolocationService,
  })  : _databaseService = databaseService,
        _ipService = ipService,
        _geolocationService = geolocationService {
    String? clientId = dotenv.env['GOOGLE_CLIENT_ID'];
    if (clientId == null || clientId.isEmpty) {
      LogService.error("GOOGLE_CLIENT_ID is not set in .env");
      throw Exception("GOOGLE_CLIENT_ID is not set");
    }

    _googleSignIn = GoogleSignIn(
      clientId: clientId,
    );

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

  /// Signs in the user with Google and handles profile creation/updating.
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

        // Update user profile
        bool updateResult = await updateUserProfileForUser(user.uid);
        if (updateResult) {
          LogService.info("User profile updated successfully for ${user.uid}");
        } else {
          LogService.error("Failed to update user profile for ${user.uid}");
        }

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

  /// Updates the user profile with the latest IP, country, active date, and platform.
  Future<bool> updateUserProfileForUser(String userId) async {
    try {
      // Gather additional information
      String ip = await _ipService.fetchUserIP();
      String country = await _geolocationService.fetchUserCountry(ip);
      String platform = "Web"; // Adjust if you have different platforms

      // Check if user profile already exists
      UserProfile? existingProfile;
      bool profileExists =
          await _databaseService.readUserProfileAsync(userId, (profile) {
        existingProfile = profile;
        LogService.info("User profile exists for $userId");
      });

      if (profileExists && existingProfile != null) {
        // Prepare updates
        Map<String, dynamic> updates = {
          'UserIP': ip,
          'UserCountry': country,
          'UserActiveDate': ServerValue.timestamp,
          'Platform': platform,
        };

        bool updateResult =
            await _databaseService.updateUserProfileAsync(userId, updates);
        if (updateResult) {
          LogService.info("User profile updated successfully for $userId");
          return true;
        } else {
          LogService.error("Failed to update user profile for $userId");
          return false;
        }
      } else {
        // Create a new user profile
        int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
        UserProfile userProfile = UserProfile(
          userId: userId,
          userName: _auth.currentUser?.displayName ?? '',
          userEmail: _auth.currentUser?.email ?? '',
          userIP: ip,
          userCountry: country,
          userJoinDate: currentTimestamp,
          userActiveDate: currentTimestamp,
          userChallenges: {}, // Initialize as empty or fetch existing challenges if needed
          userInvited: 0, // Initialize or fetch from existing data
          userInvitedBy: '', // Initialize or fetch from existing data
          userSource: 'FlutterWeb', // Adjust based on your sources
          userStatus: 'Active', // Adjust based on your logic
          platform: platform,
          amountWon: 0.0, // Initialize or fetch from existing data
        );

        bool writeResult =
            await _databaseService.writeUserProfileAsync(userProfile);
        if (writeResult) {
          LogService.info("User profile created successfully for $userId");
          return true;
        } else {
          LogService.error("Failed to create user profile for $userId");
          return false;
        }
      }
    } catch (e, stackTrace) {
      LogService.error(
          "Exception during profile update for $userId: $e", e, stackTrace);
      return false;
    }
  }

  /// Signs out the current user from both Firebase and Google Sign-In.
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

  /// Retrieves the currently signed-in [User].
  ///
  /// Returns `null` if no user is signed in.
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
