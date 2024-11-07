import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import '../constants/constants.dart';
import '../services/log_service.dart';

class WakeUpEarlyOathWidget extends StatefulWidget {
  final Function(TimeOfDay wakeUpTime, Uint8List imageBytes) onSubmit;

  const WakeUpEarlyOathWidget({Key? key, required this.onSubmit})
      : super(key: key);

  @override
  _WakeUpEarlyOathWidgetState createState() => _WakeUpEarlyOathWidgetState();
}

class _WakeUpEarlyOathWidgetState extends State<WakeUpEarlyOathWidget> {
  TimeOfDay? _wakeUpTime;
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

  void _selectWakeUpTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 6, minute: 0),
    );
    if (pickedTime != null) {
      setState(() {
        _wakeUpTime = pickedTime;
      });
      LogService.info("Wake-up time selected: $_wakeUpTime");
    }
  }

  void _submit() {
    if (_wakeUpTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your wake-up time.')),
      );
      return;
    }

    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image.')),
      );
      return;
    }

    widget.onSubmit(_wakeUpTime!, _selectedImageBytes!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          "Ready to become an early riser!",
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
          "Please select your target wake-up time and upload a screenshot of your alarm settings.",
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            color: AppColors.mainFGColor,
          ),
        ),
        const SizedBox(height: 20),
        // Wake-up Time Picker
        GestureDetector(
          onTap: _selectWakeUpTime,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.grey[200],
            ),
            child: Row(
              children: [
                Text(
                  _wakeUpTime != null
                      ? 'Wake-up Time: ${_wakeUpTime!.format(context)}'
                      : 'Tap to select wake-up time',
                  style: TextStyle(
                    color: AppColors.mainFGColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins',
                  ),
                ),
                const Spacer(),
                const Icon(Icons.access_time, color: Colors.grey),
              ],
            ),
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
                      'Tap to upload your alarm screenshot',
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
            onPressed: _submit,
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
    );
  }
}
