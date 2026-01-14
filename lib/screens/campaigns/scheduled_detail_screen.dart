import 'package:flutter/material.dart';
import '../../models/scheduled_group.dart';
import '../../models/scheduled_sms.dart';
import '../../utils/db/scheduled_db_helper.dart';
import 'add_scheduled_message_screen.dart';
import '../../utils/scheduling_utils.dart';

class ScheduledDetailScreen extends StatefulWidget {
  final ScheduledGroup group;

  const ScheduledDetailScreen({super.key, required this.group});

  @override
  State<ScheduledDetailScreen> createState() => _ScheduledDetailScreenState();
}

class _ScheduledDetailScreenState extends State<ScheduledDetailScreen> {
  bool _isScheduledEnabled = true;
  List<ScheduledSms> _messages = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    if (widget.group.id != null) {
      final msgs = await ScheduledDbHelper().getMessagesByGroupId(
        widget.group.id!,
      );
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Match screenshot white bg
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.group.title,
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
                  // TODO: Save action
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
              // Match card style in screenshot: border, rounded
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                  ),
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
                        value: _isScheduledEnabled,
                        onChanged: (value) =>
                            setState(() => _isScheduledEnabled = value),
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFFFBB03B),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search messages',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[400]),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_messages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        "No messages yet",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  )
                else
                  Container(
                    color: const Color(0xFFF6F6F6), // Light grey background
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Builder(
                      builder: (context) {
                        final filteredMessages = _messages
                            .where(
                              (m) => m.title.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                            )
                            .toList();

                        if (filteredMessages.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                "No matching messages",
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredMessages.length,
                          itemBuilder: (context, index) {
                            final msg = filteredMessages[index];
                            return _buildMessageItem(message: msg);
                          },
                        );
                      },
                    ),
                  ),

                // Footer: + Add Message
                InkWell(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AddScheduledMessageScreen(group: widget.group),
                      ),
                    );
                    _loadMessages(); // Refresh list
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                    ),
                    child: const Text(
                      '+ Add Message',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
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

  Widget _buildMessageItem({required ScheduledSms message}) {
    Color checkColor = message.status == 'sent'
        ? const Color(0xFFFBB03B)
        : Colors.grey.shade400;

    String dateText = '';
    if (message.status == 'draft') {
      dateText = 'Draft';
    } else if (message.frequency == 'Monthly' && message.scheduledDay != null) {
      dateText =
          '${message.scheduledDay}${SchedulingUtils.getDaySuffix(message.scheduledDay!)} of the month';
    } else if (message.frequency == 'Weekly' && message.scheduledDay != null) {
      dateText = 'Every ${SchedulingUtils.weekDays[message.scheduledDay! - 1]}';
    } else {
      dateText = message.frequency;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white), // Subtle border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                message.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF555555), // Slightly muted black
                ),
              ),
              if (message.status != 'draft')
                Icon(Icons.check_circle, size: 16, color: checkColor),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F1F1)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_month, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                dateText,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[400], // Match mockup muted date
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
