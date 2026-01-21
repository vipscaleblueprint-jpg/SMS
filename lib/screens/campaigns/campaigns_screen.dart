import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../welcome_message_screen.dart';
import 'scheduled_messages_screen.dart';
import '../../widgets/header_user.dart';
import 'campaign_history_screen.dart';

import 'master_sequence_screen.dart';

class CampaignsScreen extends ConsumerStatefulWidget {
  const CampaignsScreen({super.key});

  @override
  ConsumerState<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends ConsumerState<CampaignsScreen> {
  void _navigateToCampaignHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CampaignHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Profile
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: HeaderUser(),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Events Title (Buttons removed)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Campaigns',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.black.withOpacity(0.9),
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Welcome Message Card
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const WelcomeMessageScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome Message',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Send Welcome Message to new\nimported contacts',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Transform.rotate(
                              angle: -0.5, // Tilted paper plane
                              child: const Icon(
                                Icons.send,
                                color: Colors.grey,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Scheduled Message Card
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const ScheduledMessagesScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Scheduled Message',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Send Scheduled Message to new\nimported contacts',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Transform.rotate(
                              angle: -0.5,
                              child: const Icon(
                                Icons.send,
                                color: Colors.grey,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sequences Card
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MasterSequenceScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sequences',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage master sequences',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Transform.rotate(
                              angle: -0.5,
                              child: const Icon(
                                Icons.send,
                                color: Colors.grey,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add Campaign Card (Now navigates to History)
                    InkWell(
                      onTap: _navigateToCampaignHistory,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Add Event',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Create and manage campaigns',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Transform.rotate(
                              angle: -0.5,
                              child: const Icon(
                                Icons.send,
                                color: Colors.grey,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
