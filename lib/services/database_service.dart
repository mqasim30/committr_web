// services/database_service.dart

import 'package:firebase_database/firebase_database.dart';
import '../models/user_profile.dart';
import 'log_service.dart';

class DatabaseService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  /// Writes a [UserProfile] to the Realtime Database.
  Future<bool> writeUserProfileAsync(UserProfile userProfile) async {
    if (userProfile.userId.isEmpty) {
      LogService.error(
          "UserProfile's userId is empty. Cannot write to database.");
      return false;
    }

    try {
      String json = userProfile.toMap().toString(); // For logging purposes
      LogService.info("Attempting to upload user profile: $json");

      await _databaseRef
          .child("USER_PROFILES")
          .child(userProfile.userId)
          .set(userProfile.toMap());

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

  /// Reads a [UserProfile] from the Realtime Database.
  Future<bool> readUserProfileAsync(
      String userId, Function(UserProfile) onSuccess) async {
    if (userId.isEmpty) {
      LogService.error("UserId is null or empty. Cannot read from database.");
      return false;
    }

    try {
      LogService.info("Attempting to read user profile for UserId: $userId");

      DataSnapshot dataSnapshot =
          await _databaseRef.child("USER_PROFILES").child(userId).get();

      if (dataSnapshot.exists) {
        Map<dynamic, dynamic> data =
            Map<dynamic, dynamic>.from(dataSnapshot.value as Map);
        LogService.info("Retrieved user profile for $userId: $data");
        UserProfile userProfile = UserProfile.fromMap(data);
        onSuccess(userProfile);
        return true;
      } else {
        LogService.warning("User profile not found for UserId: $userId");
        return false;
      }
    } catch (e, stackTrace) {
      LogService.error(
          "Failed to read user profile for $userId: $e", e, stackTrace);
      return false;
    }
  }

  /// Updates a [UserProfile] in the Realtime Database.
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

    try {
      LogService.info(
          "Attempting to update user profile for $userId with updates: $updates");

      await _databaseRef.child("USER_PROFILES").child(userId).update(updates);

      LogService.info("User profile for $userId updated successfully.");
      return true;
    } catch (e, stackTrace) {
      LogService.error(
          "Failed to update user profile for $userId: $e", e, stackTrace);
      return false;
    }
  }
}
