import 'package:flutter/material.dart';
import 'add_scheduled_message_screen.dart';

class ScheduledMessageDetailScreen extends StatefulWidget {
  final String title;

  const ScheduledMessageDetailScreen({super.key, required this.title});

  @override
  State<ScheduledMessageDetailScreen> createState() =>
      _ScheduledMessageDetailScreenState();
}

class _ScheduledMessageDetailScreenState
    extends State<ScheduledMessageDetailScreen> {
  bool _isScheduled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
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
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Toggle
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
                      value: _isScheduled,
                      onChanged: (value) {
                        setState(() {
                          _isScheduled = value;
                        });
                      },
                      activeColor: const Color(0xFFFBB03B),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Mock List Item 1
              _buildMessageItem(
                title: 'Hello Message',
                date: '15 nth of the month',
                isDraft: false,
              ),
              const Divider(height: 1),

              // Mock List Item 2
              _buildMessageItem(
                title: 'Localize Events Message',
                date: 'Draft',
                isDraft: true,
              ),
              const Divider(height: 1),

              // Mock List Item 3
              _buildMessageItem(
                title: 'Friday Event',
                date: 'Every Wednesday',
                isDraft: false,
              ),
              const Divider(height: 1),

              // Add Message Button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddScheduledMessageScreen(),
                    ),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    '+ Add Message',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem({
    required String title,
    required String date,
    required bool isDraft,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              if (!isDraft)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFFFBB03B),
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                date,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
