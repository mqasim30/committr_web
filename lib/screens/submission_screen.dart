// lib/screens/submission_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_selector/file_selector.dart';
import 'package:firebase_database/firebase_database.dart';

import '../services/log_service.dart';
import 'main_screen.dart';
import '../constants/constants.dart';

class SubmissionScreen extends StatefulWidget {
  final String userId;
  final String challengeId;

  const SubmissionScreen({
    Key? key,
    required this.userId,
    required this.challengeId,
  }) : super(key: key);

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final _formKey = GlobalKey<FormState>();

  double? _finalWeight;
  String? _weightUnit;
  String? _challengeTitle;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    LogService.info("SubmissionScreen initState called");
    _fetchChallengeTitle();
    _fetchStoredWeightUnit();
  }

  /// Fetch the challenge title from Firebase
  Future<void> _fetchChallengeTitle() async {
    LogService.debug("Fetching challenge title for: ${widget.challengeId}");
    try {
      final challengeRef = FirebaseDatabase.instance
          .ref()
          .child('CHALLENGES')
          .child(widget.challengeId)
          // Adjust to match your actual DB key ('ChallengeTitle', 'challengeTitle', etc.)
          .child('ChallengeTitle');

      final snapshot = await challengeRef.get();
      if (snapshot.exists) {
        setState(() {
          _challengeTitle = snapshot.value as String;
        });
        LogService.info(
            "Challenge title fetched successfully: $_challengeTitle");
      } else {
        LogService.warning(
            "Challenge title not found for: ${widget.challengeId}");
      }
    } catch (e) {
      LogService.error("Error fetching challenge title: $e");
    }
  }

  /// Fetches the stored weight unit from Firebase
  Future<void> _fetchStoredWeightUnit() async {
    LogService.debug(
        "Fetching stored weight unit for user: ${widget.userId}, challenge: ${widget.challengeId}");
    try {
      final userChallengeRef = FirebaseDatabase.instance
          .ref()
          .child('USER_PROFILES')
          .child(widget.userId)
          .child('UserChallenges')
          .child(widget.challengeId);

      final snapshot = await userChallengeRef.child('ChallengeData').get();
      if (snapshot.exists) {
        final challengeData = snapshot.value as Map<dynamic, dynamic>?;
        if (challengeData != null && challengeData.containsKey('weightUnit')) {
          setState(() {
            _weightUnit = challengeData['weightUnit'] as String;
          });
          LogService.info("Stored weight unit fetched: $_weightUnit");
        } else {
          setState(() {
            _weightUnit = 'kg';
          });
          LogService.warning("Weight unit not found. Defaulting to kg.");
        }
      } else {
        setState(() {
          _weightUnit = 'kg';
        });
        LogService.warning("ChallengeData not found. Defaulting to kg.");
      }
    } catch (e) {
      setState(() {
        _weightUnit = 'kg';
      });
      LogService.error("Error fetching stored weight unit: $e");
    }
  }

  /// Lets the user pick an image from their device (web, mobile, desktop)
  Future<void> _pickImage() async {
    LogService.debug("User tapped to pick an image.");
    try {
      final typeGroup =
          XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png']);
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file != null) {
        final Uint8List bytes = await file.readAsBytes();
        if (!mounted) return;

        setState(() {
          _selectedImage = file;
          _selectedImageBytes = bytes;
        });

        LogService.info("Image selected: ${_selectedImage!.name}");
      } else {
        LogService.debug("No image was selected by the user.");
      }
    } catch (e) {
      LogService.error("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image.')),
      );
    }
  }

  /// Uploads the selected image to Firebase Storage
  Future<String?> _uploadImage() async {
    LogService.debug("Starting image upload...");
    if (_selectedImageBytes == null) {
      LogService.warning("No image bytes found to upload.");
      return null;
    }

    try {
      final fileName =
          'submission_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(widget.userId)
          .child(widget.challengeId)
          .child(fileName);

      final uploadTask = storageRef.putData(_selectedImageBytes!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      LogService.info("Image uploaded. Download URL: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      LogService.error("Error uploading image: $e");
      return null;
    }
  }

  /// Submits final data (weight & image) to Firebase
  Future<void> _submitFinalData() async {
    LogService.debug("User tapped Submit button.");
    if (!_formKey.currentState!.validate()) {
      LogService.debug("Form validation failed.");
      return;
    }

    if (_selectedImageBytes == null) {
      LogService.warning("No image was selected before submission.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image.')),
      );
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });
    LogService.debug("Submission process started. Showing loader.");

    final imageUrl = await _uploadImage();
    if (imageUrl == null) {
      setState(() {
        _isLoading = false;
      });
      LogService.error("Image upload returned null URL.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to upload image. Please try again.')),
      );
      return;
    }

    try {
      final weightValue = _finalWeight!;
      final userChallengeRef = FirebaseDatabase.instance
          .ref()
          .child('USER_PROFILES')
          .child(widget.userId)
          .child('UserChallenges')
          .child(widget.challengeId);

      LogService.debug(
          "Updating userChallenge with final weight and image URL.");
      await userChallengeRef.update({
        'ChallengeData/finalWeight': weightValue,
        'ChallengeData/submissionImageUrl': imageUrl,
        'userChallengeStatus': 'Pending',
      });

      LogService.info(
        "User ${widget.userId} submitted final data for ${widget.challengeId}",
      );

      setState(() {
        _isLoading = false;
      });

      LogService.debug("Navigating to MainScreen and showing success message.");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission completed successfully!')),
      );
    } catch (e) {
      LogService.error("Error submitting final data: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit data. Please try again.'),
        ),
      );
    }
  }

  /// Toggles the weight unit (but we’re keeping it fixed per your request)
  void _toggleWeightUnit() {
    LogService.debug("User tapped on weight unit toggle.");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Weight unit is fixed to $_weightUnit for this submission.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    LogService.debug("SubmissionScreen build() called.");

    return Scaffold(
      // Keep default white background
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            children: [
              // ----------------------------------------------------------------
              // 1) Header Section with a Row (Back Button + Centered Title)
              // ----------------------------------------------------------------
              Row(
                children: [
                  // Back Button container
                  Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.mainFGColor,
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.mainFGColor),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  // Spacer
                  const SizedBox(width: 10),
                  // Title
                  Expanded(
                    child: Center(
                      child: Text(
                        _challengeTitle == "Wake Up Early"
                            ? "Challenge Completed"
                            : "Submit Final Data",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainFGColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ----------------------------------------------------------------
              // 2) Check if loading data for challenge/weight unit
              // ----------------------------------------------------------------
              // If challengeTitle or weightUnit is null, show loader
              if (_challengeTitle == null || _weightUnit == null) ...[
                const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.mainFGColor,
                  ),
                ),
              ]

              // ----------------------------------------------------------------
              // 3) If this is the "Wake Up Early" challenge, show a motivational UI
              // ----------------------------------------------------------------
              else if (_challengeTitle == "Wake Up Early") ...[
                Expanded(
                  child: Center(
                    child: Text(
                      "Congratulations on completing the Wake Up Early challenge!\n\n"
                      "You've made fantastic progress in developing a healthy morning routine.\n\n"
                      "Please sit tight while we review your achievement and finalize the results.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.mainFGColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                if (_isLoading)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: AppColors.loadingOverlayColor.withOpacity(0.7),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.loadingIndicatorColor,
                      ),
                    ),
                  ),
              ]

              // ----------------------------------------------------------------
              // 4) Otherwise, show the standard submission form
              // ----------------------------------------------------------------
              else ...[
                // We'll show the form in an Expanded so it can scroll if needed
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          // Weight input
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppColors.mainFGColor,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Final Weight ($_weightUnit)',
                                    labelStyle: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: AppColors.mainFGColor,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: AppColors.mainFGColor,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: AppColors.mainFGColor,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your final weight.';
                                    }
                                    final weight = double.tryParse(value);
                                    if (weight == null || weight <= 0) {
                                      return 'Please enter a valid weight.';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _finalWeight = double.parse(value!);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.mainFGColor,
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: _toggleWeightUnit,
                                child: Text(
                                  _weightUnit!.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24.0),

                          // Image picker
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 220,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.mainFGColor,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                                color: Colors.white,
                              ),
                              child: _selectedImageBytes != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.memory(
                                        _selectedImageBytes!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 220,
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        'Tap to upload your final image',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          color: AppColors.mainFGColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24.0),

                          // Submit button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mainFGColor,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _submitFinalData,
                            child: const Text(
                              'Submit',
                              style: TextStyle(fontFamily: 'Poppins'),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),

                // Loading overlay if needed
                if (_isLoading)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: AppColors.loadingOverlayColor.withOpacity(0.7),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.loadingIndicatorColor,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
