// lib/screens/oath_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_selector/file_selector.dart';
import '../services/log_service.dart';
import 'package:firebase_database/firebase_database.dart';

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
  String _weightUnit = 'kg'; // Default unit
  XFile? _selectedImage; // Changed from PlatformFile to XFile
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
      String fileName = 'oath_${DateTime.now().millisecondsSinceEpoch}.jpg';
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

  /// Handles the submission of the oath
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
      // Prepare weight with unit
      String weightWithUnit =
          '${_currentWeight!.toStringAsFixed(1)} $_weightUnit';

      // Update the UserChallengeDetail's challengeData with weight and oathImageUrl
      DatabaseReference userChallengeRef = FirebaseDatabase.instance
          .ref()
          .child('USER_PROFILES')
          .child(widget.userId)
          .child('UserChallenges')
          .child(widget.challengeId);

      await userChallengeRef.update({
        'challengeData': {
          'currentWeight': weightWithUnit,
          'oathImageUrl': imageUrl,
        },
        'IsOathTaken': true,
      });

      LogService.info(
          "User ${widget.userId} has submitted oath for challenge ${widget.challengeId}");

      setState(() {
        _isLoading = false;
      });

      // Navigate back or to another screen as needed
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oath submitted successfully!')),
      );
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
        title: const Text('Take the Oath'),
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
                  // Current Weight Input with Toggle
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Current Weight',
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
                                'Tap to upload your oath image',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _submitOath,
                    child: const Text('Submit Oath'),
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
