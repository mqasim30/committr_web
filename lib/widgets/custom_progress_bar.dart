import 'package:flutter/material.dart';
import '../constants/constants.dart';

class CustomProgressBar extends StatelessWidget {
  final double progress;

  const CustomProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Progress bar background
        SizedBox(
          width: double.infinity,
          height: 30,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: AppColors.mainBgColor,
            ),
          ),
        ),
        // Percentage text overlay
        Text(
          "${(progress * 100).toStringAsFixed(1)}% completed",
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.mainFGColor,
          ),
        ),
      ],
    );
  }
}
