import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/firebase_analytics_service.dart';
import '../screens/oath_screen.dart';
import '../constants/constants.dart';
import '../services/log_service.dart';

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
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsService analyticsService = FirebaseAnalyticsService();
    analyticsService.logCustomEvent(
      screenName: 'payment_status_screen',
      action: 'open',
    );

    _paymentRef =
        FirebaseDatabase.instance.ref().child('payments/${widget.sessionId}');

    LogService.info("🔥 PaymentStatusListener initialized");
    LogService.info("🔥 Session ID: ${widget.sessionId}");
    LogService.info("🔥 User ID: ${widget.userId}");
    LogService.info("🔥 Challenge ID: ${widget.challengeId}");
    LogService.info("🔥 Pledge Amount: ${widget.pledgeAmount}");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async =>
          false, // Prevent back navigation during payment processing
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: StreamBuilder<DatabaseEvent>(
            stream: _paymentRef.onValue,
            builder: (context, snapshot) {
              LogService.info(
                  "🔥 StreamBuilder - ConnectionState: ${snapshot.connectionState}");

              if (snapshot.connectionState == ConnectionState.waiting) {
                LogService.info("🔥 Still waiting for payment data...");
                return _buildWaitingScreen();
              }

              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                LogService.info("🔥 No payment data found yet");
                return _buildWaitingScreen();
              }

              try {
                Map<dynamic, dynamic> data =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                String status = data['status'] ?? 'unknown';
                String? message = data['message'];

                LogService.info("🔥 PAYMENT STATUS RECEIVED: '$status'");
                LogService.info("🔥 PAYMENT DATA: $data");

                switch (status) {
                  case 'completed':
                    // ✅ Payment successful AND challenge joined successfully on server
                    LogService.info(
                        "🔥 ✅ Payment and challenge join successful!");
                    return _buildSuccessScreen(
                        "Payment successful! Challenge joined.");

                  case 'completed_but_join_failed':
                    // ⚠️ Payment successful BUT challenge join failed on server
                    LogService.warning(
                        "🔥 ⚠️ Payment successful but challenge join failed");
                    return _buildPartialSuccessScreen(
                        "Payment successful, but there was an issue joining the challenge. Please contact support.",
                        message);

                  case 'failed':
                    LogService.error("🔥 ❌ Payment failed");
                    return _buildFailureScreen(
                        "Payment failed. Please try again.");

                  case 'canceled':
                    LogService.info("🔥 Payment was canceled");
                    return _buildFailureScreen("Payment was canceled.");

                  default:
                    LogService.info(
                        "🔥 Unknown status: $status, continuing to wait...");
                    return _buildWaitingScreen();
                }
              } catch (e, stackTrace) {
                LogService.error(
                    "🔥 ❌ Error processing payment data: $e", e, stackTrace);
                return _buildErrorScreen("Error processing payment status.");
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Payment Status',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.mainFGColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Processing your payment...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: AppColors.mainFGColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CircularProgressIndicator(
                color: AppColors.mainFGColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen(String message) {
    // Auto-navigate to oath screen after a delay (only once)
    if (!_hasNavigated) {
      _hasNavigated = true;
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OathScreen(
                userId: widget.userId,
                challengeId: widget.challengeId,
              ),
            ),
          );
        }
      });
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Payment Successful!',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.mainFGColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  color: AppColors.mainFGColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "Redirecting to oath screen...",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CircularProgressIndicator(
                color: AppColors.mainBgColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartialSuccessScreen(String message, String? details) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Payment Processed',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.mainFGColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: AppColors.mainFGColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (details != null && details.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Details: $details",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                SizedBox(
                  width: 200,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/main',
                        (Route<dynamic> route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainBgColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Return to Challenges',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainFGColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFailureScreen(String message) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Payment Status',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.mainFGColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: AppColors.mainFGColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Go back to challenge detail
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainBgColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainFGColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/main',
                            (Route<dynamic> route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Go Home',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainFGColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorScreen(String message) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Error',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: AppColors.mainFGColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 200,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/main',
                        (Route<dynamic> route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainBgColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Return to Home',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainFGColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
