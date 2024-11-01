// lib/widgets/step_card.dart

import 'package:flutter/material.dart';
import '../models/constants.dart';

class StepCard extends StatelessWidget {
  final String text;

  const StepCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFf7f2fa),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circle Indicator
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.mainBgColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Step Text
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainFGColor,
                  height: 1.1),
            ),
          ),
        ],
      ),
    );
  }
}
