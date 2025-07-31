// lib/services/database_service.dart - SECURE VERSION

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import 'log_service.dart';

class DatabaseService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DatabaseService();

  /// SECURITY: Validate user authorization before any database operation
  bool _isAuthorized(String userId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      LogService.error("No authenticated user for database operation");
      return false;
    }

    if (currentUser.uid != userId) {
      LogService.error(
          "Unauthorized database access attempt: ${currentUser.uid} trying to access $userId");
      return false;
    }

    return true;
  }

  /// SECURITY: Validate user profile data before writing
  bool _validateUserProfile(UserProfile userProfile) {
    // Validate required fields
    if (userProfile.userId.isEmpty || userProfile.userId.length > 128) {
      LogService.error("Invalid userId in profile");
      return false;
    }

    if (userProfile.userEmail.isEmpty || userProfile.userEmail.length > 100) {
      LogService.error("Invalid userEmail in profile");
      return false;
    }

    // Validate email format
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(userProfile.userEmail)) {
      LogService.error("Invalid email format in profile");
      return false;
    }

    // Validate userName length
    if (userProfile.userName.length > 100) {
      LogService.error("userName too long in profile");
      return false;
    }

    // Validate userStatus
    if (!['Active', 'Inactive', 'Banned'].contains(userProfile.userStatus)) {
      LogService.error("Invalid userStatus in profile");
      return false;
    }

    // Validate platform
    if (!['Web', 'iOS', 'Android'].contains(userProfile.platform)) {
      LogService.error("Invalid platform in profile");
      return false;
    }

    // Validate numeric fields
    if (userProfile.userJoinDate <= 0 || userProfile.userActiveDate <= 0) {
      LogService.error("Invalid date fields in profile");
      return false;
    }

    if (userProfile.amountWon < 0 || userProfile.userInvited < 0) {
      LogService.error("Invalid numeric fields in profile");
      return false;
    }

    return true;
  }

  /// SECURITY: Sanitize user input
  Map<String, dynamic> _sanitizeUserProfile(UserProfile userProfile) {
    return {
      'UserId': userProfile.userId,
      'UserName': _sanitizeString(userProfile.userName, 100),
      'UserEmail': _sanitizeString(userProfile.userEmail, 100),
      'UserIP': _sanitizeString(userProfile.userIP, 45),
      'UserCountry': _sanitizeString(userProfile.userCountry, 10),
      'UserJoinDate': userProfile.userJoinDate,
      'UserActiveDate': userProfile.userActiveDate,
      'UserChallenges': userProfile.userChallenges
          .map((key, value) => MapEntry(key, value.toMap())),
      'UserInvited': userProfile.userInvited,
      'UserInvitedBy': _sanitizeString(userProfile.userInvitedBy, 100),
      'UserSource': _sanitizeString(userProfile.userSource, 50),
      'UserStatus': userProfile.userStatus,
      'Platform': userProfile.platform,
      'AmountWon': userProfile.amountWon,
    };
  }

  String _sanitizeString(String input, int maxLength) {
    if (input.isEmpty) return '';

    String sanitized = input;

    return sanitized.trim();
  }

  /// SECURITY: Validate update data
  bool _validateUpdateData(Map<String, dynamic> updates) {
    final allowedFields = {
      'UserIP',
      'UserCountry',
      'UserActiveDate',
      'Platform',
      'UserName',
      'AmountWon',
      'UserInvited',
      'UserStatus'
    };

    for (final entry in updates.entries) {
      final key = entry.key;
      final value = entry.value;

      // Check if field is allowed to be updated
      if (!allowedFields.contains(key)) {
        LogService.error("Attempted to update forbidden field: $key");
        return false;
      }

      // Validate field-specific constraints
      switch (key) {
        case 'UserIP':
          if (value is! String || value.length > 45) return false;
          break;
        case 'UserCountry':
          if (value is! String || value.length > 10) return false;
          break;
        case 'UserActiveDate':
          if (value is! int || value <= 0) return false;
          break;
        case 'Platform':
          if (value is! String || !['Web', 'iOS', 'Android'].contains(value))
            return false;
          break;
        case 'UserName':
          if (value is! String || value.length > 100) return false;
          break;
        case 'AmountWon':
          if (value is! double || value < 0) return false;
          break;
        case 'UserInvited':
          if (value is! int || value < 0) return false;
          break;
        case 'UserStatus':
          if (value is! String ||
              !['Active', 'Inactive', 'Banned'].contains(value)) return false;
          break;
      }
    }
    return true;
  }

  /// Writes a [UserProfile] to the Realtime Database with security checks.
  Future<bool> writeUserProfileAsync(UserProfile userProfile) async {
    if (userProfile.userId.isEmpty) {
      LogService.error(
          "UserProfile's userId is empty. Cannot write to database.");
      return false;
    }

    // SECURITY: Check authorization
    if (!_isAuthorized(userProfile.userId)) {
      return false;
    }

    // SECURITY: Validate profile data
    if (!_validateUserProfile(userProfile)) {
      return false;
    }

    try {
      LogService.info(
          "Attempting to upload user profile: ${userProfile.userId}");

      // SECURITY: Sanitize data before writing
      Map<String, dynamic> sanitizedData = _sanitizeUserProfile(userProfile);

      await _databaseRef
          .child("USER_PROFILES")
          .child(userProfile.userId)
          .set(sanitizedData);

      LogService.info(
          "User profile for ${userProfile.userId} uploaded successfully.");
      return true;
    } catch (e, stackTrace) {
      LogService.error(
          "Failed to upload user profile for ${userProfile.userId}: $e",
          e,
          stackTrace);
      return false;
    }
  }

  /// Reads a [UserProfile] from the Realtime Database with security checks.
  Future<UserProfile?> readUserProfile(String userId) async {
    if (userId.isEmpty) {
      LogService.error("UserId is null or empty. Cannot read from database.");
      return null;
    }

    // SECURITY: Check authorization
    if (!_isAuthorized(userId)) {
      return null;
    }

    try {
      LogService.info("Attempting to read user profile for UserId: $userId");

      DataSnapshot dataSnapshot =
          await _databaseRef.child("USER_PROFILES").child(userId).get();

      if (dataSnapshot.exists) {
        Map<dynamic, dynamic> data =
            Map<dynamic, dynamic>.from(dataSnapshot.value as Map);

        // SECURITY: Validate data structure before parsing
        if (!_validateProfileStructure(data)) {
          LogService.error("Invalid profile structure for user $userId");
          return null;
        }

        LogService.info("Retrieved user profile for $userId");
        UserProfile userProfile = UserProfile.fromMap(data);

        // SECURITY: Additional validation after parsing
        if (!_validateUserProfile(userProfile)) {
          LogService.error(
              "Profile validation failed after parsing for $userId");
          return null;
        }

        return userProfile;
      } else {
        LogService.warning("User profile not found for UserId: $userId");
        return null;
      }
    } catch (e, stackTrace) {
      LogService.error(
          "Failed to read user profile for $userId: $e", e, stackTrace);
      return null;
    }
  }

  /// SECURITY: Validate profile data structure
  bool _validateProfileStructure(Map<dynamic, dynamic> data) {
    final requiredFields = [
      'UserId',
      'UserEmail',
      'UserJoinDate',
      'UserActiveDate',
      'UserStatus',
      'Platform'
    ];

    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        LogService.error("Missing required field in profile: $field");
        return false;
      }
    }

    return true;
  }

  /// Updates a [UserProfile] in the Realtime Database with security checks.
  Future<bool> updateUserProfileAsync(
      String userId, Map<String, dynamic> updates) async {
    if (userId.isEmpty) {
      LogService.error("UserId is null or empty. Cannot update profile.");
      return false;
    }

    if (updates.isEmpty) {
      LogService.error("Updates map is empty. Nothing to update.");
      return false;
    }

    // SECURITY: Check authorization
    if (!_isAuthorized(userId)) {
      return false;
    }

    // SECURITY: Validate update data
    if (!_validateUpdateData(updates)) {
      return false;
    }

    try {
      LogService.info(
          "Attempting to update user profile for $userId with updates: $updates");

      // SECURITY: Sanitize update data
      Map<String, dynamic> sanitizedUpdates = {};
      updates.forEach((key, value) {
        if (value is String) {
          sanitizedUpdates[key] = _sanitizeString(value, 100);
        } else {
          sanitizedUpdates[key] = value;
        }
      });

      await _databaseRef
          .child("USER_PROFILES")
          .child(userId)
          .update(sanitizedUpdates);

      LogService.info("User profile for $userId updated successfully.");
      return true;
    } catch (e, stackTrace) {
      LogService.error(
          "Failed to update user profile for $userId: $e", e, stackTrace);
      return false;
    }
  }

  /// SECURITY: Read-only access to challenge data
  Future<Map<String, dynamic>?> readChallengeData(String challengeId) async {
    if (challengeId.isEmpty || challengeId.length > 128) {
      LogService.error("Invalid challengeId format");
      return null;
    }

    try {
      DataSnapshot snapshot =
          await _databaseRef.child("CHALLENGES").child(challengeId).get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      } else {
        LogService.warning("Challenge not found: $challengeId");
        return null;
      }
    } catch (e, stackTrace) {
      LogService.error("Error reading challenge data: $e", e, stackTrace);
      return null;
    }
  }

  /// SECURITY: Check if user has access to specific challenge data
  Future<bool> hasAccessToChallenge(String userId, String challengeId) async {
    if (!_isAuthorized(userId)) {
      return false;
    }

    try {
      DataSnapshot snapshot = await _databaseRef
          .child("USER_PROFILES")
          .child(userId)
          .child("UserChallenges")
          .child(challengeId)
          .get();

      return snapshot.exists;
    } catch (e, stackTrace) {
      LogService.error("Error checking challenge access: $e", e, stackTrace);
      return false;
    }
  }

  /// SECURITY: Get database reference for specific user data only
  DatabaseReference? getUserDataReference(String userId, String path) {
    if (!_isAuthorized(userId)) {
      return null;
    }

    // Only allow access to user's own data
    return _databaseRef.child("USER_PROFILES").child(userId).child(path);
  }
}
