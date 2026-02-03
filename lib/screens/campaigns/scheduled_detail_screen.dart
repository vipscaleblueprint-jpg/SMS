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
  late bool _isScheduledEnabled;
  List<ScheduledSms> _messages = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _isScheduledEnabled = widget.group.isActive;
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
      msgs.sort((a, b) {
        final isDraftA = a.status == 'draft';
        final isDraftB = b.status == 'draft';
        if (isDraftA && !isDraftB) return -1;
        if (!isDraftA && isDraftB) return 1;

        final dateA = a.scheduledTime;
        final dateB = b.scheduledTime;
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateA.compareTo(dateB);
      });
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleGroupStatus(bool value) async {
    if (widget.group.id == null) return;

    final updatedGroup = ScheduledGroup(
      id: widget.group.id,
      title: widget.group.title,
      isActive: value,
    );

    // Update group status
    await ScheduledDbHelper().updateGroup(updatedGroup);

    // Update all non-sent messages status
    await ScheduledDbHelper().updateMessageStatusByGroup(
      widget.group.id!,
      value ? 'pending' : 'draft',
    );

    setState(() {
      _isScheduledEnabled = value;
    });

    // Refresh messages to show updated statuses
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Match screenshot white bg
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                        onChanged: _toggleGroupStatus,
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFFFBB03B),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey.shade400,
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
                    color: Colors.transparent, // Light grey background
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
                      '+ Add SMS',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  AddScheduledMessageScreen(group: widget.group),
            ),
          );
          _loadMessages(); // Refresh list
        },
        backgroundColor: const Color(0xFFFBB03B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMessageItem({required ScheduledSms message}) {
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

    final isDraft = message.status == 'draft';
    final isUnpublished = !_isScheduledEnabled;

    final margin = isDraft
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 0)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 6);

    final padding = isDraft
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
        : const EdgeInsets.all(16);

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddScheduledMessageScreen(
              group: widget.group,
              messageToEdit: message,
            ),
          ),
        );
        _loadMessages();
      },
      child: Container(
        margin: margin,
        padding: padding,
        decoration: isDraft
            ? const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFF1F1F1))),
              )
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  message.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDraft || isUnpublished
                        ? Colors.grey[400]
                        : const Color(0xFF555555),
                  ),
                ),
                if (!isDraft)
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: message.status == 'sent'
                        ? (isUnpublished
                              ? Colors.grey.shade400
                              : const Color(0xFFFBB03B))
                        : Colors.grey.shade400,
                  ),
              ],
            ),
            if (!isDraft) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFF1F1F1)),
              const SizedBox(height: 8),
            ] else
              const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 16,
                  color: isDraft || isUnpublished
                      ? Colors.grey[300]
                      : Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  dateText,
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
