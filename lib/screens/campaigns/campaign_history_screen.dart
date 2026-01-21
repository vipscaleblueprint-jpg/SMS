import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'create_campaign_screen.dart';
import '../../widgets/list/events_list.dart';
import '../../models/events.dart';
import '../../providers/events_provider.dart';
import 'event_actions_screen.dart';
import '../../widgets/header_user.dart';

class CampaignHistoryScreen extends ConsumerStatefulWidget {
  const CampaignHistoryScreen({super.key});

  @override
  ConsumerState<CampaignHistoryScreen> createState() =>
      _CampaignHistoryScreenState();
}

class _CampaignHistoryScreenState extends ConsumerState<CampaignHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToCreateCampaign() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateCampaignScreen()),
    );
  }

  void _navigateToEditCampaign(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateCampaignScreen(event: event),
      ),
    );
  }

  void _deleteEvent(Event event) {
    if (event.id != null) {
      ref.read(eventsProvider.notifier).deleteEvent(event.id!);
    }
  }

  void _showDeleteEventDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Delete this Campaign? ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  children: [
                    const TextSpan(
                      text: 'Are you sure you want to delete the ',
                    ),
                    TextSpan(
                      text: '${event.name} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: 'Campaign?\n\n'),
                    const TextSpan(
                      text:
                          'Deleting  this campaign will result in the following actions that you may want to consider before moving forward.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      _deleteEvent(event);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Delete campaign',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Back Button and User Profile
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const HeaderUser(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Title and Add Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                              IconButton(
                                onPressed: _navigateToCreateCampaign,
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFBB03B,
                                    ).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: Color(0xFFFBB03B),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Search Bar
                          TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Search Campaigns',
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: Colors.grey.shade400,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  color: const Color(0xFFF8F9FA), // Matches content background
                  child: EventsList(
                    searchQuery: _searchQuery,
                    showSearch: false,
                    onDelete: _showDeleteEventDialog,
                    onEdit: _navigateToEditCampaign,
                    onTap: (event) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EventActionsScreen(
                            eventId: event.id!,
                            eventTitle: event.name,
                            eventDate: DateFormat(
                              'MMM dd, yyyy hh:mm a',
                            ).format(event.date),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
