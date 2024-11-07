// lib/screens/pledge_amount_selection_screen.dart

import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../services/select_pledge_service.dart';
import '../widgets/loading_overlay.dart';
import '../constants/constants.dart';

class PledgeAmountSelectionScreen extends StatefulWidget {
  final Challenge challenge;

  const PledgeAmountSelectionScreen({
    Key? key,
    required this.challenge,
  }) : super(key: key);

  @override
  _PledgeAmountSelectionScreenState createState() =>
      _PledgeAmountSelectionScreenState();
}

class _PledgeAmountSelectionScreenState
    extends State<PledgeAmountSelectionScreen> {
  bool isLoading = false;
  double? selectedPledgeAmount; // Track the selected pledge amount

  final List<double> pledgeAmounts = [35.0, 55.0, 75.0, 95.0];

  @override
  void initState() {
    super.initState();
    selectedPledgeAmount = 55.0; // Pre-select the popular option
  }

  double calculateAdditionalReward(double pledgeAmount) {
    return pledgeAmount - 5;
  }

  Future<void> selectPledge(double amount) async {
    setState(() {
      isLoading = true;
    });

    await selectPledgeAmount(context, widget.challenge, amount).then((success) {
      setState(() {
        isLoading = false;
      });

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to join challenge.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Content with Extra Bottom Padding
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Be A Better You\nIn a Fun Way",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: AppColors.mainFGColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pledge Amount:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: AppColors.mainFGColor,
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  children: pledgeAmounts.map((amount) {
                    double additionalReward = calculateAdditionalReward(amount);
                    double totalReward = amount + additionalReward;
                    bool isSelected = selectedPledgeAmount == amount;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedPledgeAmount =
                              amount; // Update selected option
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? AppColors
                                      .mainBgColor // Highlight selected option
                                  : Colors.grey,
                              width: isSelected
                                  ? 2.5
                                  : 1.0, // Thicker border if selected
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isSelected
                                          ? AppColors
                                              .mainBgColor // Change color if selected
                                          : Colors.grey[300],
                                      radius: 10,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '\$${amount.toInt()}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                        color: AppColors.mainFGColor,
                                      ),
                                    ),
                                    if (amount == 55.0)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.mainBgColor,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Popular',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Poppins',
                                              color: AppColors.mainFGColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'If 50% of the members complete this challenge you will get additional reward. \$${amount.toInt()} + \$${additionalReward.toInt()} (\$${totalReward.toInt()} in total)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    color: AppColors.mainFGColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(
                    height:
                        150), // Extra padding for scroll to ensure content visibility
              ],
            ),
          ),
          if (isLoading) const LoadingOverlay(),

          // Close (X) Button at Top Right
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.close, color: AppColors.mainFGColor),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          // Footer Section with Continue Button and Terms and Conditions
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Continue to Payment Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: selectedPledgeAmount != null
                        ? () => selectPledge(
                            selectedPledgeAmount!) // Only proceed if an option is selected
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainBgColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Continue to Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: AppColors.mainFGColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
