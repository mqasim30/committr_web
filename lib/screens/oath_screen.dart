// lib/screens/oath_screen.dart - SECURE VERSION

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../constants/constants.dart';
import '../models/challenge.dart';
import '../services/firebase_analytics_service.dart';
import '../services/user_service.dart';
import '../utils/challenge_helper.dart';
import '../services/log_service.dart';
import '../widgets/weight_oath_widget.dart';
import '../widgets/reduce_screen_time_oath_widget.dart';
import '../widgets/wake_up_early_oath_widget.dart';

class OathScreen extends StatefulWidget {
  final String userId;
  final String challengeId;

  const OathScreen({
    super.key,
    required this.userId,
    required this.challengeId,
  });

  @override
  _OathScreenState createState() => _OathScreenState();
}

class _OathScreenState extends State<OathScreen> {
  bool _isLoading = false;
  Challenge? _challenge;
  ChallengeType _challengeType = ChallengeType.Unknown;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsService analyticsService = FirebaseAnalyticsService();
    analyticsService.logCustomEvent(
      screenName: 'oath_screen',
      action: 'open',
    );
    _fetchChallenge();
  }

  Future<void> _fetchChallenge() async {
    try {
      DatabaseReference challengeRef = FirebaseDatabase.instance
          .ref()
          .child('CHALLENGES')
          .child(widget.challengeId);
      DataSnapshot snapshot = await challengeRef.get();
      if (snapshot.exists) {
        Map<String, dynamic> challengeMap =
            Map<String, dynamic>.from(snapshot.value as Map);
        Challenge challenge = Challenge.fromMap(challengeMap);
        setState(() {
          _challenge = challenge;
          _challengeType =
              ChallengeHelper.getChallengeType(_challenge!.challengeTitle);
        });
      } else {
        LogService.warning(
            "Challenge with ID ${widget.challengeId} does not exist.");
        _showErrorAndExit("Challenge not found.");
      }
    } catch (e, stackTrace) {
      LogService.error(
          "Error fetching Challenge ${widget.challengeId}: $e", e, stackTrace);
      _showErrorAndExit("Failed to load challenge details.");
    }
  }

  void _showErrorAndExit(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/main',
      (Route<dynamic> route) => false,
    );
  }

  Future<String?> _uploadImage(Uint8List imageBytes) async {
    try {
      // Validate file size (5MB limit)
      if (imageBytes.length > 5 * 1024 * 1024) {
        throw Exception('Image file too large. Maximum size is 5MB.');
      }

      String fileName = 'oath_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child(widget.userId)
          .child(widget.challengeId)
          .child(fileName);

      // Set metadata for additional security
      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': widget.userId,
          'challengeId': widget.challengeId,
          'type': 'oath',
        },
      );

      UploadTask uploadTask = storageRef.putData(imageBytes, metadata);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      LogService.info(
          "Image uploaded successfully. Download URL: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      LogService.error("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _submitOath(Map<String, dynamic> oathData) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Validate user authorization
      final currentUser = _userService.getCurrentUser();
      if (currentUser == null || currentUser.uid != widget.userId) {
        throw Exception('Unauthorized: User mismatch');
      }

      // Submit oath using secure Cloud Function
      bool success = await _userService.submitOath(
        challengeId: widget.challengeId,
        oathData: oathData,
      );

      if (success) {
        LogService.info(
            "User ${widget.userId} has submitted oath for challenge ${widget.challengeId}");

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oath submitted successfully!')),
        );

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/main',
          (Route<dynamic> route) => false,
        );
      } else {
        throw Exception('Failed to submit oath');
      }
    } catch (e, stackTrace) {
      LogService.error("Error submitting oath: $e", e, stackTrace);
      setState(() {
        _isLoading = false;
      });

      String userMessage = 'Failed to submit oath. Please try again.';
      if (e.toString().contains('Unauthorized')) {
        userMessage = 'Session expired. Please sign in again.';
      } else if (e.toString().contains('already taken')) {
        userMessage = 'Oath has already been submitted for this challenge.';
      } else if (e.toString().contains('Invalid')) {
        userMessage = 'Please check your input and try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_challenge == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _buildChallengeUI(),
          ),
          // Close (X) Button at Top Right
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.close, color: AppColors.mainFGColor),
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/main',
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ),
          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChallengeUI() {
    switch (_challengeType) {
      case ChallengeType.Lose4Percent:
      case ChallengeType.Lose10Percent:
      case ChallengeType.MaintainWeight:
        return WeightOathWidget(
          isLoading: _isLoading,
          onSubmit: (double weight, String unit, Uint8List imageBytes) async {
            String? imageUrl = await _uploadImage(imageBytes);
            if (imageUrl == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Failed to upload image. Please try again.')),
              );
              return;
            }

            await _submitOath({
              'startingWeight': weight,
              'weightUnit': unit,
              'oathImageUrl': imageUrl,
            });
          },
        );

      case ChallengeType.ReduceScreenTime:
        return ReduceScreenTimeOathWidget(
          isLoading: _isLoading,
          onSubmit: (Uint8List imageBytes, String dailyUsage) async {
            String? imageUrl = await _uploadImage(imageBytes);
            if (imageUrl == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Failed to upload image. Please try again.')),
              );
              return;
            }

            await _submitOath({
              'dailyUsage': dailyUsage,
              'oathImageUrl': imageUrl,
            });
          },
        );

      case ChallengeType.WakeUpEarly:
        return WakeUpEarlyOathWidget(
          isLoading: _isLoading,
          onSubmit: (TimeOfDay wakeUpTime) async {
            await _submitOath({
              'wakeUpTime':
                  '${wakeUpTime.hour}:${wakeUpTime.minute.toString().padLeft(2, '0')}',
            });
          },
        );

      default:
        return Center(
          child: Text(
            'Unknown Challenge Type',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              color: AppColors.mainFGColor,
            ),
          ),
        );
    }
  }
}
