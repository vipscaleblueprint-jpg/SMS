import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../send/add_sms_screen.dart';
import '../../providers/sms_provider.dart';
import '../../models/sms.dart';

class EventActionsScreen extends ConsumerStatefulWidget {
  final int eventId;
  final String eventTitle;
  final String eventDate;

  const EventActionsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
  });

  @override
  ConsumerState<EventActionsScreen> createState() => _EventActionsScreenState();
}

class _EventActionsScreenState extends ConsumerState<EventActionsScreen> {
  bool _isActionsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final smsListAsync = ref.watch(eventSmsProvider(widget.eventId));

    DateTime? eventDateTime;
    try {
      eventDateTime = DateFormat(
        'MMM dd, yyyy hh:mm a',
      ).parse(widget.eventDate);
    } catch (e) {
      eventDateTime = DateTime.now();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.eventTitle,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBB03B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Event Actions Header with Toggle
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Event Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Switch(
                        value: _isActionsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isActionsEnabled = value;
                          });
                        },
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFFFBB03B),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Action List Items
                smsListAsync.when(
                  data: (smsList) {
                    final beforeList = <Sms>[];
                    final afterList = <Sms>[];

                    for (var sms in smsList) {
                      if (sms.schedule_time != null &&
                          sms.schedule_time!.isBefore(eventDateTime!)) {
                        beforeList.add(sms);
                      } else {
                        afterList.add(sms);
                      }
                    }

                    // Sort lists if needed (assuming DB returns insertion order or similar, but date sort is better)
                    beforeList.sort(
                      (a, b) => a.schedule_time!.compareTo(b.schedule_time!),
                    );
                    // afterList sort? undefined schedule_time (null) go last or first?
                    // Let's keep them as is or sort by ID.

                    if (smsList.isEmpty) {
                      // Even if no SMS, show Event Card
                      return ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        children: [_buildEventCard()],
                      );
                    }

                    return ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: [
                        ...beforeList.map((sms) => _buildSmsItem(sms)),
                        // Spacer or Separator?
                        if (beforeList.isNotEmpty) const SizedBox(height: 16),
                        _buildEventCard(),
                        if (afterList.isNotEmpty) const SizedBox(height: 16),
                        ...afterList.map((sms) => _buildSmsItem(sms)),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),

                const Divider(height: 1),

                // Add SMS Button
                InkWell(
                  onTap: () {
                    DateTime? parsedEventDate;
                    try {
                      parsedEventDate = DateFormat(
                        'MMM dd, yyyy hh:mm a',
                      ).parse(widget.eventDate);
                    } catch (e) {
                      // print or handle error if needed
                    }

                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) => AddSmsScreen(
                              eventTitle: widget.eventTitle,
                              eventId: widget.eventId,
                              eventDate: parsedEventDate,
                            ),
                          ),
                        )
                        .then((_) {
                          // Refreshes handled by provider watcher usually if invalidated, but explicit refresh ensures it
                          void _ = ref.refresh(
                            eventSmsProvider(widget.eventId),
                          );
                        });
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Text(
                          '+ Add SMS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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
      ),
    );
  }

  Widget _buildEventCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.eventTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              Icon(
                Icons.check_circle,
                color: _isActionsEnabled
                    ? const Color(0xFFFBB03B)
                    : Colors.grey,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                widget.eventDate,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // State for selections
  final Set<int> _selectedIds = {};

  Widget _buildSmsItem(Sms sms) {
    // Format date if available
    final dateStr = sms.schedule_time != null
        ? DateFormat('MMMM dd, yyyy hh:mm a').format(sms.schedule_time!)
        : (sms.sentTimeStamps != null
              ? DateFormat('MMMM dd, yyyy hh:mm a').format(sms.sentTimeStamps!)
              : 'Draft');

    final isSelected = sms.id != null && _selectedIds.contains(sms.id);

    return InkWell(
      onTap: () {
        if (sms.id == null) return;
        setState(() {
          if (_selectedIds.contains(sms.id)) {
            _selectedIds.remove(sms.id);
          } else {
            _selectedIds.add(sms.id!);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.grey.shade300 : Colors.transparent,
            width: 10.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.eventTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: _isActionsEnabled
                        ? const Color(0xFFFBB03B)
                        : Colors.grey,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
