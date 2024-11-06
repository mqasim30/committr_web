import 'package:flutter/material.dart';
import '../constants/constants.dart';

class ProfilePage extends StatelessWidget {
  final String name;
  final String? profilePictureUrl;
  final int challengesCount;
  final int wonCount;
  final int peopleInvitedCount;
  final String joinedDate;

  const ProfilePage({
    super.key,
    required this.name,
    required this.challengesCount,
    required this.wonCount,
    required this.peopleInvitedCount,
    required this.joinedDate, // Initialize joined date
    this.profilePictureUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.all(10),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Curved Blue Header Background with Profile Picture
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 180,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.fromARGB(255, 22, 149, 0),
                            AppColors.mainBgColor,
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(40),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 120,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 48,
                          backgroundImage: profilePictureUrl != null
                              ? NetworkImage(profilePictureUrl!)
                              : const AssetImage(
                                      'assets/images/default_avatar.png')
                                  as ImageProvider,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 185,
                      left: MediaQuery.of(context).size.width * 0.5 + 20,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: AppColors.mainFGColor,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Joined $joinedDate Ago",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.mainFGColor,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 16),

                // Challenges, Won, and People Invited Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ChallengeStatCard(
                              title: "Challenges", value: challengesCount),
                          const SizedBox(width: 8),
                          _ChallengeStatCard(title: "Won", value: wonCount),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _ChallengeStatCard(
                          title: "People Invited",
                          value: peopleInvitedCount,
                          fullWidth: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// A stat card widget with consistent padding for top and bottom, and specific width for fullWidth
class _ChallengeStatCard extends StatelessWidget {
  final String title;
  final int value;
  final bool fullWidth;

  const _ChallengeStatCard({
    super.key,
    required this.title,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: fullWidth
          ? const BoxConstraints(
              minWidth: 296, maxWidth: 296, minHeight: 101, maxHeight: 101)
          : const BoxConstraints(
              minWidth: 140, maxWidth: 140, minHeight: 101, maxHeight: 101),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 16, horizontal: 8), // Consistent top and bottom padding
          child: Column(
            children: [
              Text(
                value.toString(),
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
