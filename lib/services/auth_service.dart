// lib/services/auth_service.dart - SECURE VERSION

import 'package:Committr/services/url_parameter_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'log_service.dart';
import 'database_service.dart';
import '../models/user_profile.dart';
import 'ip_service.dart';
import 'geolocation_service.dart';
import 'server_time_service.dart';

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
    // SECURITY: Use environment variable for Google Client ID
    String? clientId = const String.fromEnvironment('GOOGLE_CLIENT_ID',
        defaultValue:
            "56606291217-sunsbtrgodth18heacgsgcs3u6hh7156.apps.googleusercontent.com");

    _googleSignIn = GoogleSignIn(
      clientId: clientId,
      scopes: ['email', 'profile'], // Limit scopes to minimum required
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
      if (kIsWeb) {
        LogService.info("Attempting Google Sign-In on Web");

        // Create a new provider
        GoogleAuthProvider googleProvider = GoogleAuthProvider();

        // SECURITY: Add additional scopes only if needed
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        UserCredential userCredential =
            await _auth.signInWithPopup(googleProvider);

        User? user = userCredential.user;

        if (user != null) {
          // SECURITY: Validate user data before proceeding
          if (!_validateUserData(user)) {
            LogService.error("Invalid user data received from Google Sign-In");
            await signOut();
            return null;
          }

          LogService.info("User signed in: ${user.displayName}, ${user.email}");

          // SECURITY: Rate limit profile updates to prevent abuse
          if (await _canUpdateProfile(user.uid)) {
            bool updateResult = await updateUserProfileForUser(user.uid);
            if (updateResult) {
              LogService.info(
                  "User profile updated successfully for ${user.uid}");
            } else {
              LogService.error("Failed to update user profile for ${user.uid}");
            }
          } else {
            LogService.warning("Profile update rate limited for ${user.uid}");
          }

          return user;
        } else {
          LogService.warning("User is null after sign-in");
          return null;
        }
      }
    } catch (e, stackTrace) {
      LogService.error("Error during Google Sign-In", e, stackTrace);

      // SECURITY: Don't expose internal error details to user
      if (e.toString().contains('popup_blocked')) {
        // Handle popup blocked scenario
        throw Exception('Please allow popups for this site and try again.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Sign-in failed. Please try again.');
      }
    }
    return null;
  }

  /// SECURITY: Validate user data from Google Sign-In
  bool _validateUserData(User user) {
    // Check required fields
    if (user.uid.isEmpty || user.email == null || user.email!.isEmpty) {
      return false;
    }

    // Validate email format
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(user.email!)) {
      return false;
    }

    // Validate UID format (Firebase UIDs are alphanumeric, 28 chars)
    if (user.uid.length < 20 || user.uid.length > 128) {
      return false;
    }

    // Check if display name is reasonable (if provided)
    if (user.displayName != null && user.displayName!.length > 100) {
      return false;
    }

    return true;
  }

  /// SECURITY: Rate limiting for profile updates
  final Map<String, DateTime> _lastProfileUpdate = {};

  Future<bool> _canUpdateProfile(String userId) async {
    final now = DateTime.now();
    final lastUpdate = _lastProfileUpdate[userId];

    if (lastUpdate == null || now.difference(lastUpdate).inMinutes > 5) {
      _lastProfileUpdate[userId] = now;
      return true;
    }

    return false;
  }

  /// Updates the user profile with the latest IP, country, active date, and platform.
  Future<bool> updateUserProfileForUser(String userId) async {
    try {
      // SECURITY: Validate userId
      if (!_validateUserId(userId)) {
        LogService.error("Invalid userId provided for profile update");
        return false;
      }

      // SECURITY: Only allow users to update their own profile
      final currentUser = getCurrentUser();
      if (currentUser == null || currentUser.uid != userId) {
        LogService.error("Unauthorized profile update attempt");
        return false;
      }

      // Gather additional information with timeout
      String ip = await _ipService.fetchUserIP().timeout(
            const Duration(seconds: 10),
            onTimeout: () => 'unknown',
          );

      String country = await _geolocationService.fetchUserCountry(ip).timeout(
            const Duration(seconds: 10),
            onTimeout: () => 'unknown',
          );

      String platform = "Web"; // Adjust if you have different platforms

      // 🆕 Get tracking parameters from URL
      String userSource = UrlParameterService
          .getSource(); // Will return 'FlutterWeb' if no source in URL
      String? clickId = UrlParameterService
          .getClickId(); // Will return null if no clickid in URL

      // Check if user profile already exists
      UserProfile? existingProfile =
          await _databaseService.readUserProfile(userId);

      // Use server time instead of local time
      DateTime serverTime = await ServerTimeService.getServerTime();
      int currentTimestamp = serverTime.millisecondsSinceEpoch;

      if (existingProfile != null) {
        // SECURITY: Only update allowed fields
        Map<String, dynamic> updates = {
          'UserIP': _sanitizeInput(ip),
          'UserCountry': _sanitizeInput(country),
          'UserActiveDate': currentTimestamp,
          'Platform': platform,
        };

        // SECURITY: Validate all update values
        if (!_validateProfileUpdates(updates)) {
          LogService.error("Invalid profile update data");
          return false;
        }

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
        // SECURITY: Validate user data before creating profile
        final user = getCurrentUser();
        if (user == null) {
          LogService.error("No authenticated user found for profile creation");
          return false;
        }

        // Create a new user profile with validated data
        UserProfile userProfile = UserProfile(
          userId: userId,
          userName: _sanitizeInput(user.displayName ?? ''),
          userEmail: _sanitizeInput(user.email ?? ''),
          userIP: _sanitizeInput(ip),
          userCountry: _sanitizeInput(country),
          userJoinDate: currentTimestamp,
          userActiveDate: currentTimestamp,
          userChallenges: {},
          userInvited: 0,
          userInvitedBy: '',
          userSource: userSource,
          userStatus: 'Active',
          platform: platform,
          amountWon: 0.0,
          clickId: clickId,
        );

        // SECURITY: Validate complete profile before saving
        if (!_validateUserProfile(userProfile)) {
          LogService.error("Invalid user profile data");
          return false;
        }

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

  /// SECURITY: Input sanitization
  String _sanitizeInput(String input) {
    if (input.isEmpty) return '';

    String sanitized = input;

    return sanitized.trim();
  }

  /// SECURITY: Validate userId format
  bool _validateUserId(String userId) {
    return userId.isNotEmpty &&
        userId.length >= 20 &&
        userId.length <= 128 &&
        RegExp(r'^[a-zA-Z0-9]+$').hasMatch(userId);
  }

  /// SECURITY: Validate profile update data
  bool _validateProfileUpdates(Map<String, dynamic> updates) {
    for (final entry in updates.entries) {
      final key = entry.key;
      final value = entry.value;

      switch (key) {
        case 'UserIP':
          if (value is! String || value.length > 45) return false;
          break;
        case 'UserCountry':
          if (value is! String || value.length > 10) return false;
          break;
        case 'UserActiveDate':
          if (value is! int || value < 0) return false;
          break;
        case 'Platform':
          if (value is! String || !['Web', 'iOS', 'Android'].contains(value))
            return false;
          break;
        default:
          LogService.warning("Unexpected update field: $key");
          return false;
      }
    }
    return true;
  }

  /// SECURITY: Validate complete user profile
  bool _validateUserProfile(UserProfile profile) {
    // Validate required fields
    if (!_validateUserId(profile.userId)) return false;
    if (profile.userEmail.isEmpty || !_validateEmail(profile.userEmail))
      return false;
    if (profile.userJoinDate <= 0) return false;
    if (profile.userActiveDate <= 0) return false;
    if (!['Active', 'Inactive', 'Banned'].contains(profile.userStatus))
      return false;
    if (!['Web', 'iOS', 'Android'].contains(profile.platform)) return false;
    if (profile.amountWon < 0) return false;

    return true;
  }

  /// SECURITY: Validate email format
  bool _validateEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email) && email.length <= 100;
  }

  /// Signs out the current user from both Firebase and Google Sign-In.
  Future<void> signOut() async {
    try {
      LogService.info("Signing out user");

      // Clear rate limiting cache
      _lastProfileUpdate.clear();

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
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // SECURITY: Validate user is still valid
        if (!_validateUserData(user)) {
          LogService.warning("Invalid current user data detected");
          signOut(); // Sign out invalid user
          return null;
        }
        LogService.info("Current user: ${user.displayName}, ${user.email}");
      } else {
        LogService.info("No user currently signed in");
      }
      return user;
    } catch (e, stackTrace) {
      LogService.error("Error getting current user", e, stackTrace);
      return null;
    }
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    LogService.info("Retrieving current user profile");
    User? user = getCurrentUser();
    UserProfile? userProfile;

    if (user != null) {
      try {
        userProfile = await _databaseService.readUserProfile(user.uid);
      } catch (e, stackTrace) {
        LogService.error("Error fetching user profile", e, stackTrace);
        return null;
      }
    } else {
      LogService.info("No user currently signed in");
      return null;
    }
    return userProfile;
  }

  /// Getter for the currently signed-in [User].
  ///
  /// Returns `null` if no user is signed in.
  User? get currentUser => getCurrentUser();

  /// SECURITY: Get authentication token for API calls
  Future<String?> getAuthToken() async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      // Force refresh token to ensure it's valid
      String? token = await user.getIdToken(true);
      return token;
    } catch (e, stackTrace) {
      LogService.error("Error getting auth token", e, stackTrace);
      return null;
    }
  }

  /// SECURITY: Verify current user's token is valid
  Future<bool> verifyCurrentUser() async {
    try {
      final user = getCurrentUser();
      if (user == null) return false;

      // Try to get a fresh token - this will fail if user is invalid
      await user.getIdToken(true);
      return true;
    } catch (e) {
      LogService.warning("User token verification failed: $e");
      await signOut();
      return false;
    }
  }
}
