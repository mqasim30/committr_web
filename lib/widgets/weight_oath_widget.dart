// lib/widgets/weight_oath_widget.dart

import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import '../constants/constants.dart';
import '../services/log_service.dart';

class WeightOathWidget extends StatefulWidget {
  final Function(double weight, String unit, Uint8List imageBytes) onSubmit;
  final bool isLoading;

  const WeightOathWidget({
    super.key,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  _WeightOathWidgetState createState() => _WeightOathWidgetState();
}

class _WeightOathWidgetState extends State<WeightOathWidget> {
  final _formKey = GlobalKey<FormState>();
  double? _currentWeight;
  String _weightUnit = 'kg';
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

  void _toggleWeightUnit() {
    setState(() {
      _weightUnit = _weightUnit == 'kg' ? 'lb' : 'kg';
    });
    LogService.info("Weight unit toggled to $_weightUnit");
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image.')),
      );
      return;
    }

    _formKey.currentState!.save();

    widget.onSubmit(_currentWeight!, _weightUnit, _selectedImageBytes!);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
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
                  cursorColor: AppColors.mainFGColor,
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
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
                        'Tap to upload your oath image',
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
