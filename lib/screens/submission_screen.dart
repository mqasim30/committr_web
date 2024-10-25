// lib/screens/submission_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_selector/file_selector.dart';
import '../services/log_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main_screen.dart'; // Import MainScreen

class SubmissionScreen extends StatefulWidget {
  final String userId;
  final String challengeId;

  const SubmissionScreen({
    Key? key,
    required this.userId,
    required this.challengeId,
  }) : super(key: key);

  @override
  _SubmissionScreenState createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  double? _finalWeight;
  String _weightUnit = 'kg'; // Default unit
  XFile? _selectedImage; // Using XFile for compatibility
  Uint8List? _selectedImageBytes; // Store image bytes
  bool _isLoading = false;

  /// Picks an image from the device (supports web, mobile, and desktop)
  Future<void> _pickImage() async {
    try {
      // Define the types of files to accept
      final XTypeGroup typeGroup = XTypeGroup(
        label: 'images',
        extensions: ['jpg', 'jpeg', 'png'],
      );

      // Open the file selector
      final XFile? file = await openFile(
        acceptedTypeGroups: [typeGroup],
      );

      if (file != null) {
        // Read the file bytes
        final Uint8List bytes = await file.readAsBytes();

        if (!mounted) return;

        setState(() {
          _selectedImage = file;
          _selectedImageBytes = bytes;
        });

        LogService.info("Image selected: ${_selectedImage!.name}");
      }
    } catch (e) {
      LogService.error("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image.')),
      );
    }
  }

  /// Uploads the image to Firebase Storage
  Future<String?> _uploadImage() async {
    if (_selectedImageBytes == null) return null;

    try {
      String fileName =
          'submission_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child(widget.userId)
          .child(widget.challengeId)
          .child(fileName);

      // Use putData with the image bytes
      UploadTask uploadTask = storageRef.putData(_selectedImageBytes!);

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

  /// Handles the submission of the final weight and image
  Future<void> _submitFinalData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image.')),
      );
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    String? imageUrl = await _uploadImage();

    if (imageUrl == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to upload image. Please try again.')),
      );
      return;
    }

    try {
      // Save final weight and submission image
      double weightValue = _finalWeight!;
      String unit = _weightUnit;

      // Update the UserChallengeDetail's challengeData with final weight and submissionImageUrl
      DatabaseReference userChallengeRef = FirebaseDatabase.instance
          .ref()
          .child('USER_PROFILES')
          .child(widget.userId)
          .child('UserChallenges')
          .child(widget.challengeId);

      await userChallengeRef.update({
        'challengeData/finalWeight': weightValue,
        'challengeData/submissionImageUrl': imageUrl,
        'userChallengeStatus': 'Completed',
      });

      LogService.info(
          "User ${widget.userId} has submitted final data for challenge ${widget.challengeId}");

      setState(() {
        _isLoading = false;
      });

      // Navigate back to MainScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (Route<dynamic> route) => false,
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
            content: Text('Failed to submit data. Please try again.')),
      );
    }
  }

  /// Toggles the weight unit between kg and lb
  void _toggleWeightUnit() {
    setState(() {
      _weightUnit = _weightUnit == 'kg' ? 'lb' : 'kg';
    });
    LogService.info("Weight unit toggled to $_weightUnit");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Final Data'),
      ),
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Final Weight Input with Toggle
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Final Weight',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
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
                        onPressed: _toggleWeightUnit,
                        child: Text(_weightUnit.toUpperCase()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Image Picker
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                        color: Colors.grey[200],
                      ),
                      child: _selectedImageBytes != null
                          ? Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                            )
                          : const Center(
                              child: Text(
                                'Tap to upload your final image',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _submitFinalData,
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
