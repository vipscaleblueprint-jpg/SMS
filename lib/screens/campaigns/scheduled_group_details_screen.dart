import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/scheduled_group.dart';
import '../../models/sms.dart';
import '../../providers/sms_provider.dart';
import '../../providers/scheduled_groups_provider.dart';
import 'add_sms_screen.dart';

class ScheduledGroupDetailsScreen extends ConsumerStatefulWidget {
  final ScheduledGroup group;

  const ScheduledGroupDetailsScreen({super.key, required this.group});

  @override
  ConsumerState<ScheduledGroupDetailsScreen> createState() =>
      _ScheduledGroupDetailsScreenState();
}

class _ScheduledGroupDetailsScreenState
    extends ConsumerState<ScheduledGroupDetailsScreen> {
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.group.isActive;
  }

  String _formatRecurrence(String? recurrence) {
    if (recurrence == null || recurrence == 'Draft') return 'Draft';
    if (recurrence.startsWith('Monthly:')) {
      final day = recurrence.split(':')[1];
      return '$day nth of the month';
    } else if (recurrence.startsWith('Weekly:')) {
      final day = recurrence.split(':')[1];
      return 'Every $day';
    }
    return recurrence;
  }

  @override
  Widget build(BuildContext context) {
    final smsList = ref.watch(smsProvider);
    final filteredSms = smsList
        .where((sms) => sms.group_id == widget.group.id)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.group.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  // Save group state if changed
                  if (_isEnabled != widget.group.isActive) {
                    ref
                        .read(scheduledGroupsProvider.notifier)
                        .toggleGroup(widget.group, _isEnabled);
                  }
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Master Toggle Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Scheduled SMS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Switch(
                          value: _isEnabled,
                          onChanged: (val) {
                            setState(() => _isEnabled = val);
                          },
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFFFBB03B),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // SMS List Items
                  if (filteredSms.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No messages added yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...filteredSms.asMap().entries.map((entry) {
                      final index = entry.key;
                      final sms = entry.value;
                      final isLast = index == filteredSms.length - 1;

                      return _buildSmsItem(sms, isLast);
                    }).toList(),

                  // Add Message Button
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddSmsScreen(
                            eventTitle: widget.group.title,
                            groupId: widget.group.id,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFF1F1F1)),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, size: 18, color: Colors.black87),
                          SizedBox(width: 8),
                          Text(
                            'Add Message',
                            style: TextStyle(
                              fontSize: 14,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSmsItem(Sms sms, bool isLast) {
    final bool isDraft = sms.status == SmsStatus.draft;
    final String scheduleText = _formatRecurrence(sms.recurrence);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddSmsScreen(
              eventTitle: widget.group.title,
              groupId: widget.group.id,
              smsToEdit: sms,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : BorderSide(color: Colors.grey.shade100),
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
                    sms.title?.isNotEmpty == true
                        ? sms.title!
                        : 'Untitled Message',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (!isDraft)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFFFBB03B),
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  scheduleText,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
