// lib/widgets/wake_up_early_progress_widget.dart

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../constants/constants.dart';
import '../models/challenge.dart';
import '../models/user_challenge_detail.dart';
import '../utils/challenge_helper.dart';
import '../services/server_time_service.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';
import 'package:intl/intl.dart';

class WakeUpEarlyProgressWidget extends StatefulWidget {
  final Challenge challenge;
  final UserChallengeDetail userChallengeDetail;
  final DateTime currentDate;
  final AuthService authService;

  const WakeUpEarlyProgressWidget({
    Key? key,
    required this.challenge,
    required this.userChallengeDetail,
    required this.currentDate,
    required this.authService,
  }) : super(key: key);

  @override
  _WakeUpEarlyProgressWidgetState createState() =>
      _WakeUpEarlyProgressWidgetState();
}

class _WakeUpEarlyProgressWidgetState extends State<WakeUpEarlyProgressWidget> {
  bool _isSubmitting = false;
  Map<String, dynamic> _checkInData = {};

  @override
  void initState() {
    super.initState();
    _fetchCheckInData();
  }

  /// Recursively converts a Map with dynamic keys to a Map with String keys.
  Map<String, dynamic> _deepConvert(Map<dynamic, dynamic> original) {
    Map<String, dynamic> converted = {};
    original.forEach((key, value) {
      String stringKey = key.toString();
      if (value is Map) {
        converted[stringKey] = _deepConvert(value);
      } else if (value is List) {
        converted[stringKey] = _deepConvertList(value);
      } else {
        converted[stringKey] = value;
      }
    });
    return converted;
  }

  /// Recursively converts a List, ensuring all nested Maps have String keys.
  List<dynamic> _deepConvertList(List<dynamic> original) {
    return original.map((item) {
      if (item is Map) {
        return _deepConvert(item);
      } else if (item is List) {
        return _deepConvertList(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// Fetches existing check-in data from Firebase
  Future<void> _fetchCheckInData() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance
          .ref()
          .child('USER_PROFILES')
          .child(widget.authService.currentUser!.uid)
          .child('UserChallenges')
          .child(widget.challenge.challengeId)
          .child('ChallengeData')
          .child('checkIns');

      DataSnapshot snapshot = await ref.get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> rawData = snapshot.value as Map<dynamic, dynamic>;
        LogService.info("Raw Check-In Data Fetched: $rawData"); // Log raw data
        Map<String, dynamic> convertedData = _deepConvert(rawData);
        LogService.info(
            "Converted Check-In Data: $convertedData"); // Log converted data
        setState(() {
          _checkInData = convertedData;
        });
      } else {
        LogService.info("No existing check-in data found.");
      }
    } catch (e) {
      LogService.error("Error fetching check-in data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch check-in data: $e')),
      );
    }
  }

  /// Submits a daily check-in
  Future<void> _submitCheckIn() async {
    setState(() {
      _isSubmitting = true;
    });

    LogService.info("Initiating check-in submission...");

    try {
      // Step 1: Fetch Server Time in UTC
      DateTime serverTimeLocal = await ServerTimeService.getServerTime();
      LogService.info("Server Time (Local): $serverTimeLocal");

      // Step 2: Retrieve Stored Time Difference (serverTime - localTime)
      DatabaseReference challengeDataRef = FirebaseDatabase.instance
          .ref()
          .child('USER_PROFILES')
          .child(widget.authService.currentUser!.uid)
          .child('UserChallenges')
          .child(widget.challenge.challengeId)
          .child('ChallengeData');

      DataSnapshot snapshot = await challengeDataRef.get();
      if (!snapshot.exists) {
        LogService.error("Challenge data not found.");
        throw Exception(
            "Challenge data not found. Please take the oath first.");
      }

      // Step 5: Generate Date Key based on Server Time's UTC Date
      String dateKey =
          '${serverTimeLocal.year}-${serverTimeLocal.month.toString().padLeft(2, '0')}-${serverTimeLocal.day.toString().padLeft(2, '0')}';
      LogService.info("Date Key for Check-In: $dateKey");

      // Step 6: Check if already checked in today
      DatabaseReference todayCheckInRef = FirebaseDatabase.instance
          .ref()
          .child('USER_PROFILES')
          .child(widget.authService.currentUser!.uid)
          .child('UserChallenges')
          .child(widget.challenge.challengeId)
          .child('ChallengeData')
          .child('checkIns')
          .child(dateKey);

      DataSnapshot todayCheckInSnapshot = await todayCheckInRef.get();
      if (todayCheckInSnapshot.exists) {
        throw Exception("Check-in for today has already been recorded.");
      }

      // Step 7: Store Check-In Data
      await todayCheckInRef.set({
        'checkInTime': serverTimeLocal.toIso8601String(),
        'checkedIn': true,
      });
      LogService.info("Check-In Data Stored Successfully.");

      // Step 8: Update local state
      setState(() {
        _checkInData[dateKey] = {
          'checkInTime': serverTimeLocal.toIso8601String(),
          'checkedIn': true,
        };
        _isSubmitting = false;
      });

      LogService.info("Check-In recorded at: $serverTimeLocal");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily check-in successful!')),
      );
    } catch (e) {
      LogService.error("Error submitting check-in: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-in failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  /// Determines if the user woke up on time based on check-in time and committed wake-up time
  /// Determines if the user woke up on time based on check-in time and committed wake-up time
  bool _didUserWakeUpOnTime(
      DateTime checkInTime, String committedWakeUpTime, String dateKey) {
    LogService.info("Determining wake-up status...");
    LogService.info("Check-In Time (Local): $checkInTime");
    LogService.info("Committed Wake-Up Time: $committedWakeUpTime");
    LogService.info("Date Key: $dateKey");

    // Parse the committed wake-up time (format: 'HH:mm')
    final parts = committedWakeUpTime.split(':');
    if (parts.length != 2) {
      LogService.error(
          "Invalid committedWakeUpTime format: $committedWakeUpTime");
      return false;
    }

    int committedHour;
    int committedMinute;
    try {
      committedHour = int.parse(parts[0]);
      committedMinute = int.parse(parts[1]);
      LogService.info("Parsed Committed Hour: $committedHour");
      LogService.info("Parsed Committed Minute: $committedMinute");
    } catch (e) {
      LogService.error("Error parsing committedWakeUpTime: $e");
      return false;
    }

    // Extract year, month, day from dateKey
    List<String> dateParts = dateKey.split('-');
    if (dateParts.length != 3) {
      LogService.error("Invalid dateKey format: $dateKey");
      return false;
    }

    int year, month, day;
    try {
      year = int.parse(dateParts[0]);
      month = int.parse(dateParts[1]);
      day = int.parse(dateParts[2]);
      LogService.info(
          "Parsed Date Key - Year: $year, Month: $month, Day: $day");
    } catch (e) {
      LogService.error("Error parsing dateKey: $e");
      return false;
    }

    // **Create DateTime for committed wake-up time on the dateKey day in LOCAL time**
    DateTime committedDateTimeLocal = DateTime(
      year,
      month,
      day,
      committedHour,
      committedMinute,
    );
    LogService.info("Committed DateTime (Local): $committedDateTimeLocal");

    // Calculate the latest allowed check-in time (e.g., 60 minutes after wake-up)
    DateTime latestAllowedTimeLocal =
        committedDateTimeLocal.add(const Duration(minutes: 60));
    LogService.info(
        "Latest Allowed Check-In Time (Local): $latestAllowedTimeLocal");

    // **Comparison Logic:**
    // Check if checkInTime is >= committedDateTimeLocal AND <= latestAllowedTimeLocal
    bool isOnTime = (checkInTime.isAfter(committedDateTimeLocal) ||
            checkInTime.isAtSameMomentAs(committedDateTimeLocal)) &&
        !checkInTime.isAfter(latestAllowedTimeLocal);
    LogService.info("Is On Time: $isOnTime");

    return isOnTime;
  }

  @override
  Widget build(BuildContext context) {
    // Generate today's date key based on currentDate
    String todayDateKey =
        '${widget.currentDate.year}-${widget.currentDate.month.toString().padLeft(2, '0')}-${widget.currentDate.day.toString().padLeft(2, '0')}';
    LogService.info("Today's Date Key: $todayDateKey");

    // Check if the user has already checked in today
    bool hasCheckedInToday = _checkInData.containsKey(todayDateKey) &&
        _checkInData[todayDateKey]['checkedIn'] == true;
    LogService.info("Has Checked-In Today: $hasCheckedInToday");

    final startDateUtc = DateTime.fromMillisecondsSinceEpoch(
        widget.challenge.challengeStartTimestamp,
        isUtc: true);
    final endDateUtc = DateTime.fromMillisecondsSinceEpoch(
        widget.challenge.challengeEndTimestamp,
        isUtc: true);

    // Normalize currentDate by setting time to midnight UTC
    DateTime normalizedCurrentDate = DateTime.utc(
      widget.currentDate.year,
      widget.currentDate.month,
      widget.currentDate.day,
    );

    // Normalize startDateUtc and endDateUtc
    DateTime normalizedStartDate = DateTime.utc(
      startDateUtc.year,
      startDateUtc.month,
      startDateUtc.day,
    );

    DateTime normalizedEndDate = DateTime.utc(
      endDateUtc.year,
      endDateUtc.month,
      endDateUtc.day,
    );

    // Determine the last date to display in check-in history
    DateTime displayEndDate = normalizedCurrentDate.isBefore(normalizedEndDate)
        ? normalizedCurrentDate
        : normalizedEndDate;

    final daysLeft =
        ChallengeHelper.calculateDaysLeft(endDateUtc, widget.currentDate);
    LogService.info("Days Left: $daysLeft");

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display Days Left
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ChallengeInfoCard(
                    title: "Days Left",
                    value: "$daysLeft",
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Daily Check-In Button
              ElevatedButton(
                onPressed:
                    hasCheckedInToday || _isSubmitting ? null : _submitCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainBgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.mainFGColor,
                          strokeWidth: 2,
                        ),
                      )
                    : hasCheckedInToday
                        ? const Text(
                            'Already Checked-In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: AppColors.mainFGColor,
                            ),
                          )
                        : const Text(
                            'Daily Check-In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: AppColors.mainFGColor,
                            ),
                          ),
              ),
              const SizedBox(height: 16),
              // Check-In History
              _buildCheckInHistory(normalizedStartDate, displayEndDate),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the check-in history UI
  Widget _buildCheckInHistory(
      DateTime startDateUtc, DateTime displayEndDateUtc) {
    List<Widget> checkInCards = [];

    // Iterate from startDate to displayEndDate
    DateTime currentDate = DateTime.utc(
      startDateUtc.year,
      startDateUtc.month,
      startDateUtc.day,
    );

    DateTime displayEndDate = DateTime.utc(
      displayEndDateUtc.year,
      displayEndDateUtc.month,
      displayEndDateUtc.day,
    );

    while (!currentDate.isAfter(displayEndDate)) {
      String dateKey =
          '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
      LogService.info("Processing Check-In for Date Key: $dateKey");

      Map<String, dynamic>? dayData =
          _checkInData[dateKey] as Map<String, dynamic>?;

      // Display date in 'MM/dd/yyyy' format
      String displayDate = DateFormat('MM/dd/yyyy').format(currentDate);

      if (dayData != null && dayData['checkedIn'] == true) {
        DateTime checkInTime = DateTime.parse(dayData['checkInTime']);
        LogService.info("Check-In Time Retrieved: $checkInTime");

        String formattedTime = DateFormat('h:mm a').format(checkInTime);
        LogService.info("Formatted Check-In Time: $formattedTime");

        // Retrieve user's committed wake-up time
        String? committedWakeUpTime =
            widget.userChallengeDetail.challengeData['wakeUpTime'];
        LogService.info(
            "Retrieved Committed Wake-Up Time: $committedWakeUpTime");

        bool onTime = false;
        if (committedWakeUpTime != null && committedWakeUpTime.isNotEmpty) {
          onTime =
              _didUserWakeUpOnTime(checkInTime, committedWakeUpTime, dateKey);
        }

        String status = onTime ? 'On Time' : 'Not On Time';
        LogService.info("Determined Status for $dateKey: $status");

        checkInCards.add(_CheckInCard(
          date: displayDate,
          status: status,
          time: formattedTime,
        ));
      } else {
        // If the date is today and no check-in exists, do not mark as 'Missed'
        bool isToday = currentDate.year == widget.currentDate.year &&
            currentDate.month == widget.currentDate.month &&
            currentDate.day == widget.currentDate.day;

        if (!isToday) {
          LogService.info(
              "No Check-In Found for Date Key: $dateKey. Marking as Missed.");
          checkInCards.add(_CheckInCard(
            date: displayDate,
            status: 'Missed',
            time: '--:--',
          ));
        } else {
          LogService.info("Date Key: $dateKey is Today. No action taken.");
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Check-In History:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: AppColors.mainFGColor,
          ),
        ),
        const SizedBox(height: 8),
        checkInCards.isNotEmpty
            ? Column(
                children: checkInCards,
              )
            : const Text(
                'No check-ins yet.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: AppColors.mainFGColor,
                ),
              ),
      ],
    );
  }
}

/// Widget to display individual check-in entries
class _CheckInCard extends StatelessWidget {
  final String date;
  final String status;
  final String time;

  const _CheckInCard({
    required this.date,
    required this.status,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    LogService.info(
        "Rendering Check-In Card: Date=$date, Status=$status, Time=$time");

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'On Time':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Not On Time':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case 'Missed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(
          date,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: AppColors.mainFGColor,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Status: $status',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: statusColor,
              ),
            ),
          ],
        ),
        trailing: Text(
          time,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: AppColors.mainFGColor,
          ),
        ),
      ),
    );
  }
}

/// Widget to display challenge information cards
class _ChallengeInfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _ChallengeInfoCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 24,
                  color: AppColors.mainFGColor,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.mainFGColor,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
