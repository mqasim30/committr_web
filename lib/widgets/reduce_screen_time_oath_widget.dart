// lib/widgets/reduce_screen_time_oath_widget.dart

import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import '../constants/constants.dart';
import '../services/log_service.dart';

class ReduceScreenTimeOathWidget extends StatefulWidget {
  final Function(Uint8List imageBytes) onSubmit;
  final bool isLoading;

  const ReduceScreenTimeOathWidget({
    super.key,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  _ReduceScreenTimeOathWidgetState createState() =>
      _ReduceScreenTimeOathWidgetState();
}

class _ReduceScreenTimeOathWidgetState
    extends State<ReduceScreenTimeOathWidget> {
  Uint8List? _selectedImageBytes;

  Future<void> _pickImage() async {
    try {
      final XTypeGroup typeGroup =
          XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png']);
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file != null) {
        final Uint8List bytes = await file.readAsBytes();

        if (!mounted) return;

        setState(() {
          _selectedImageBytes = bytes;
        });

        LogService.info("Image selected: ${file.name}");
      }
    } catch (e) {
      LogService.error("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image.')),
      );
    }
  }

  void _submit() {
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image.')),
      );
      return;
    }

    widget.onSubmit(_selectedImageBytes!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          "Let's start your journey to reduce screen time!",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: AppColors.mainFGColor,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Please upload a screenshot of your current screen time usage. Here's how to find it:",
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            color: AppColors.mainFGColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "• For Android: Go to Settings > Digital Wellbeing & parental controls > Dashboard.",
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: AppColors.mainFGColor,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "• For iOS: Go to Settings > Screen Time > See All Activity.",
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: AppColors.mainFGColor,
          ),
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
                ? Center(
                    child: Image.memory(
                      _selectedImageBytes!,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  )
                : const Center(
                    child: Text(
                      'Tap to upload your screen time screenshot',
                      style: TextStyle(
                        color: AppColors.mainFGColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
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
            onPressed: widget.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: widget.isLoading
                ? CircularProgressIndicator(
                    color: AppColors.mainFGColor,
                  )
                : Text(
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
    );
  }
}
