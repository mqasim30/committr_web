// lib/screens/payment_status_listener.dart

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'oath_screen.dart';
import '../widgets/loading_overlay.dart';
import '../services/log_service.dart';
import '../services/user_service.dart';
import '../models/challenge.dart';

class PaymentStatusListener extends StatefulWidget {
  final String sessionId;
  final String userId;
  final String challengeId;
  final double pledgeAmount;

  const PaymentStatusListener({
    super.key,
    required this.sessionId,
    required this.userId,
    required this.challengeId,
    required this.pledgeAmount,
  });

  @override
  _PaymentStatusListenerState createState() => _PaymentStatusListenerState();
}

class _PaymentStatusListenerState extends State<PaymentStatusListener> {
  late DatabaseReference _paymentRef;
  bool _navigated = false;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _paymentRef =
        FirebaseDatabase.instance.ref().child('payments/${widget.sessionId}');
    LogService.info(
        "Initialized PaymentStatusListener for sessionId: ${widget.sessionId}, userId: ${widget.userId}, challengeId: ${widget.challengeId}, pledgeAmount: ${widget.pledgeAmount}");
  }

  /// Fetches the Challenge object from Firebase Realtime Database
  Future<Challenge?> _getChallengeById(String challengeId) async {
    try {
      DatabaseReference challengeRef =
          FirebaseDatabase.instance.ref().child('CHALLENGES/$challengeId');
      DataSnapshot snapshot = await challengeRef.get();

      if (snapshot.exists) {
        Map<String, dynamic> challengeMap =
            Map<String, dynamic>.from(snapshot.value as Map);
        Challenge challenge = Challenge.fromMap(challengeMap);
        LogService.info("Fetched Challenge: ${challenge.challengeTitle}");
        return challenge;
      } else {
        LogService.warning("Challenge with ID $challengeId does not exist.");
        return null;
      }
    } catch (e, stackTrace) {
      LogService.error(
          "Error fetching Challenge $challengeId: $e", e, stackTrace);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _paymentRef.onValue,
        builder: (context, snapshot) {
          // Show LoadingOverlay while waiting for data
          if (snapshot.connectionState == ConnectionState.waiting) {
            LogService.debug("Awaiting payment confirmation...");
            return const LoadingOverlay();
          }

          // Handle absence of data
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            LogService.warning(
                "No payment data found for sessionId: ${widget.sessionId}");
            return const Center(
                child: Text('Awaiting payment confirmation...'));
          }

          try {
            Map<dynamic, dynamic> data =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

            String status = data['status'] ?? 'unknown';
            LogService.info(
                "Payment status retrieved: $status for sessionId: ${widget.sessionId}");

            if (status == 'completed' && !_navigated) {
              _navigated = true;
              LogService.info(
                  "Payment completed. Initiating challenge join process.");

              WidgetsBinding.instance.addPostFrameCallback((_) async {
                // Fetch Challenge
                Challenge? challenge =
                    await _getChallengeById(widget.challengeId);

                if (challenge == null) {
                  LogService.error("Challenge is null. Cannot join challenge.");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Failed to retrieve challenge details.')),
                  );
                  setState(() {
                    _navigated = false;
                  });
                  return;
                }

                // Call joinChallenge with pledgeAmount
                bool joinSuccess = await _userService.joinChallenge(
                    context, widget.userId, challenge, widget.pledgeAmount);

                if (joinSuccess) {
                  LogService.info(
                      "Successfully joined challenge ${challenge.challengeId}");
                  // Navigate to OathScreen upon successful join
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OathScreen(
                        userId: widget.userId,
                        challengeId: widget.challengeId,
                      ),
                    ),
                  );
                } else {
                  LogService.error(
                      "Failed to join challenge ${challenge.challengeId}");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to join challenge.')),
                  );
                }
              });

              return const Center(
                child: Text(
                  'Payment Successful! Redirecting...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            } else if (status != 'completed') {
              LogService.info("Current payment status: $status");
              return Center(
                child: Text(
                  'Payment Status: $status',
                  style: const TextStyle(fontSize: 18),
                ),
              );
            } else {
              LogService.debug(
                  "Payment status is 'completed' but already navigated.");
              return const LoadingOverlay();
            }
          } catch (e, stackTrace) {
            LogService.error(
                "Error processing payment data: $e", e, stackTrace);
            return Center(
              child: Text(
                'Error retrieving payment status.',
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
            );
          }
        },
      ),
    );
  }
}
