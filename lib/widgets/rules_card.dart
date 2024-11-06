// lib/widgets/rules_card.dart

import 'package:flutter/material.dart';
import '../constants/constants.dart';

class RulesCard extends StatelessWidget {
  final String ruleText;
  final int ruleIndex;

  const RulesCard({super.key, required this.ruleText, required this.ruleIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFf7f2fa), // Elevated background
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              ruleText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: 'Poppins',
                color: AppColors.mainFGColor,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
