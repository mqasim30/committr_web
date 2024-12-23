import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final String userName;
  final String? profilePictureUrl;
  final String tagline;

  const SideMenu({
    super.key,
    required this.userName,
    this.profilePictureUrl,
    this.tagline = "Stay committed, stay successful!",
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Improved Header Section
            Container(
              height: 180,
              width: double.infinity,
              color: const Color(0xFF9FE870), // Solid color background
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundImage: profilePictureUrl != null
                          ? NetworkImage(profilePictureUrl!)
                          : const AssetImage('assets/images/default_avatar.png')
                              as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Color(0xFFF5F5F5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tagline,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: Color(0xFFF5F5F5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Enhanced Menu Options
            _buildMenuTile(
              icon: Icons.info_outline,
              title: 'Terms',
              onTap: () => _showModalContent(context, 'Terms',
                  'These are the dummy terms of service for this app. Users are required to follow all guidelines for challenge participation. Non-compliance may result in account suspension.'),
            ),
            _buildMenuTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => _showModalContent(context, 'Privacy Policy',
                  'We value your privacy. Any data collected is used solely to improve your experience in the app. No data is shared with third parties without explicit consent.'),
            ),
            _buildMenuTile(
              icon: Icons.help_outline,
              title: 'FAQs',
              onTap: () => _showFAQs(context),
            ),
            _buildMenuTile(
              icon: Icons.contact_support_outlined,
              title: 'Contact Us',
              onTap: () => _showModalContent(context, 'Contact Us',
                  'For any issues or suggestions, contact us at:\n\nsupport@example.com\n\nWe’re here to help you stay committed!'),
            ),
          ],
        ),
      ),
    );
  }

  ListTile _buildMenuTile({
    required IconData icon,
    required String title,
    required Function() onTap,
    Color backgroundColor = const Color(0xFFF5F5F5),
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              const Color(0xFF083400).withOpacity(0.1), // Background for icon
        ),
        child: Icon(icon, color: const Color(0xFF083400), size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF083400),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xFF9FE870),
      ),
      tileColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8), // Adjust padding
    );
  }

  void _showModalContent(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF083400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFAQs(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'FAQs',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: const [
                      FAQItem(
                        question: 'What is this app?',
                        answer:
                            'This app helps you commit to and track various challenges like waking up early, losing weight, and more.',
                      ),
                      FAQItem(
                        question: 'How do I join a challenge?',
                        answer:
                            'You can join a challenge by browsing the available challenges and clicking the "Join" button.',
                      ),
                      FAQItem(
                        question: 'Is my data secure?',
                        answer:
                            'Yes, we use industry-standard encryption to ensure your data is safe and secure.',
                      ),
                      FAQItem(
                        question: 'Can I leave a challenge?',
                        answer:
                            'Yes, you can leave a challenge at any time from the active challenges section.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF083400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const FAQItem({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
