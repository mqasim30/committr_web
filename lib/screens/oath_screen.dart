import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../services/log_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/constants.dart';

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
  final _formKey = GlobalKey<FormState>();
  double? _currentWeight;
  String _weightUnit = 'kg';
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final XTypeGroup typeGroup =
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
      }
    } catch (e) {
      LogService.error("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image.')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImageBytes == null) return null;

    try {
      String fileName = 'oath_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child(widget.userId)
          .child(widget.challengeId)
          .child(fileName);

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

  Future<void> _submitOath() async {
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
      double weightValue = _currentWeight!;
      String unit = _weightUnit;

      DatabaseReference userChallengeRef = FirebaseDatabase.instance
          .ref()
          .child('USER_PROFILES')
          .child(widget.userId)
          .child('UserChallenges')
          .child(widget.challengeId);

      await userChallengeRef.update({
        'ChallengeData': {
          'startingWeight': weightValue,
          'currentWeight': weightValue,
          'weightUnit': unit,
          'oathImageUrl': imageUrl,
        },
        'IsOathTaken': true,
      });

      LogService.info(
          "User ${widget.userId} has submitted oath for challenge ${widget.challengeId}");

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oath submitted successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      LogService.error("Error submitting oath: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to submit oath. Please try again.')),
      );
    }
  }

  void _toggleWeightUnit() {
    setState(() {
      _weightUnit = _weightUnit == 'kg' ? 'lb' : 'kg';
    });
    LogService.info("Weight unit toggled to $_weightUnit");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Congrats on\ncommitting\nto a fresh start!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: AppColors.mainFGColor,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Weight Input and Toggle Button
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          cursorColor:
                              AppColors.mainFGColor, // Change cursor color here
                          decoration: InputDecoration(
                            labelText: 'Current Weight',
                            labelStyle: TextStyle(
                              color: AppColors.mainFGColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Poppins',
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.mainFGColor,
                                width: 2.0,
                              ),
                            ),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your current weight.';
                            }
                            final weight = double.tryParse(value);
                            if (weight == null || weight <= 0) {
                              return 'Please enter a valid weight.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _currentWeight = double.parse(value!);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _toggleWeightUnit,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(0),
                          child: Row(
                            children: [
                              _buildUnitToggle('kg'),
                              _buildUnitToggle('lb'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Image Picker with Fit Adjustment
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
                          ? Center(
                              // Wrap with Center widget to ensure alignment
                              child: Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.contain, // Adjusted for fitting
                                alignment: Alignment
                                    .center, // Ensure it stays centered
                              ),
                            )
                          : const Center(
                              child: Text(
                                'Tap to upload your oath image',
                                style: TextStyle(
                                  color: AppColors.mainFGColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitOath,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainBgColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Submit Oath',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          color: AppColors.mainFGColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Close (X) Button at Top Right
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.close, color: AppColors.mainFGColor),
              onPressed: () => Navigator.pop(context),
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

  Widget _buildUnitToggle(String unit) {
    final isActive = _weightUnit == unit;
    return Container(
      width: 45,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? AppColors.mainBgColor : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        unit.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.mainFGColor : Colors.black,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
