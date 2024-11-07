// lib/widgets/wake_up_early_oath_widget.dart

import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../services/log_service.dart';
import '../services/server_time_service.dart';

class WakeUpEarlyOathWidget extends StatefulWidget {
  final Function(TimeOfDay wakeUpTime) onSubmit;
  final bool isLoading;

  const WakeUpEarlyOathWidget({
    Key? key,
    required this.onSubmit,
    required this.isLoading,
  }) : super(key: key);

  @override
  _WakeUpEarlyOathWidgetState createState() => _WakeUpEarlyOathWidgetState();
}

class _WakeUpEarlyOathWidgetState extends State<WakeUpEarlyOathWidget> {
  TimeOfDay? _wakeUpTime;

  /// Selects the user's wake-up time using a time picker dialog.
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

  /// Submits the oath data by calculating the time difference between the server and local time.
  void _submit() async {
    if (_wakeUpTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your wake-up time.')),
      );
      return;
    }
    widget.onSubmit(_wakeUpTime!);
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
          "Please select your target wake-up time.",
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
                ? const CircularProgressIndicator(
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
