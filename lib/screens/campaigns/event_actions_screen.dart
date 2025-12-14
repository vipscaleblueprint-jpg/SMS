import 'package:flutter/material.dart';
import '../send/add_sms_screen.dart';

class EventActionsScreen extends StatefulWidget {
  final String eventTitle;
  final String eventDate;

  const EventActionsScreen({
    super.key,
    required this.eventTitle,
    required this.eventDate,
  });

  @override
  State<EventActionsScreen> createState() => _EventActionsScreenState();
}

class _EventActionsScreenState extends State<EventActionsScreen> {
  bool _isActionsEnabled = true;

  @override
  Widget build(BuildContext context) {
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
      body: Padding(
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
              _buildActionItem(
                title: widget.eventTitle,
                date: 'February 19, 2024 03:00 AM',
                isSelected: true,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildActionItem(
                title: widget.eventTitle,
                date: 'February 19, 2024 03:00 AM',
                isSelected: false,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildActionItem(
                title: widget.eventTitle,
                date: 'February 19, 2024 03:00 AM',
                isSelected: true,
              ),
              const Divider(height: 1),

              // Add SMS Button
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          AddSmsScreen(eventTitle: widget.eventTitle),
                    ),
                  );
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
    );
  }

  Widget _buildActionItem({
    required String title,
    required String date,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFFFBB03B),
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                date,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
