import 'package:flutter/material.dart';
import 'dart:async'; // Add import

class Message {
  final String id;
  final String text;
  final DateTime timestamp;
  int currentSent;
  final int totalToSend;
  bool isStopButtonVisible;
  bool isCanceled;
  bool isCompleted; // Add isCompleted

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    this.currentSent = 0,
    this.totalToSend = 1200, // Updated mock total
    this.isStopButtonVisible = false,
    this.isCanceled = false,
    this.isCompleted = false,
  });
}

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final Map<String, Timer> _timers = {}; // Track active timers

  // TODO: Remove this mock data later
  bool _showVipChip = true;

  @override
  void dispose() {
    _recipientController.dispose();
    _messageController.dispose();
    // Cancel all timers
    for (var timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _simulateSending(Message message) {
    // Simulate sending roughly 1200 messages over a few seconds
    const tickDuration = Duration(milliseconds: 100);
    const messagesPerTick = 10; // Speed of sending

    _timers[message.id] = Timer.periodic(tickDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (message.isCanceled) {
          timer.cancel();
          _timers.remove(message.id);
          return;
        }

        message.currentSent += messagesPerTick;

        // Ensure we don't exceed total
        if (message.currentSent >= message.totalToSend) {
          message.currentSent = message.totalToSend;
          message.isCompleted = true;
          timer.cancel();
          _timers.remove(message.id);
        }
      });
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = Message(
      id: DateTime.now().toString(),
      text: _messageController.text,
      timestamp: DateTime.now(),
      currentSent: 0, // Start at 0
    );

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    // Start simulation
    _simulateSending(newMessage);
  }

  void _toggleStopButton(int index) {
    if (_messages[index].isCanceled || _messages[index].isCompleted)
      return; // Cannot stop if canceled or done
    setState(() {
      // Toggle the specific message's stop button visibility
      _messages[index].isStopButtonVisible =
          !_messages[index].isStopButtonVisible;
    });
  }

  void _showStopConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Text(
                'Are you sure you want to\nstop sending?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  height: 1.2,
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1),
            InkWell(
              onTap: () {
                setState(() {
                  final msg = _messages[index];
                  msg.isCanceled = true;
                  msg.isStopButtonVisible = false;
                  // Cancel the timer if active
                  _timers[msg.id]?.cancel();
                  _timers.remove(msg.id);
                });
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text(
                  'Stop',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFF5252), // Red
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1),
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text(
                  'Cancel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header and Recipient Input
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New mass text',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              // --- MOCK DATA START: VIP SCALE CHIP ---
              if (_showVipChip)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'VIP SCALE',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _showVipChip = false),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // --- MOCK DATA END ---
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _recipientController,
                      decoration: const InputDecoration(
                        hintText: 'Recipient',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        contentPadding: EdgeInsets.only(bottom: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement add recipient logic
                    },
                    icon: Container(
                      decoration: const BoxDecoration(
                        color: Color(
                          0xFFE0E0E0,
                        ), // Light grey for the + button circle
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Central Content Area (Message List)
        Expanded(
          child: Container(
            color: const Color(0xFFE0E0E0), // Light grey placeholder
            width: double.infinity,
            child: _messages.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      // Display nicely with time formatting
                      final timeStr =
                          "${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')} ${msg.timestamp.hour >= 12 ? 'pm' : 'am'}";

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: GestureDetector(
                          onLongPress: () => _toggleStopButton(index),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Message Bubble
                              Container(
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        msg.text,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Sending Status / Stop UI
                              if (msg.isStopButtonVisible)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      height: 32,
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _showStopConfirmationDialog(index),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFFF5252,
                                          ), // Red color
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Stop sending',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    // Count below the button
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '${msg.currentSent}',
                                            style: const TextStyle(
                                              color: Color(0xFFFBB03B),
                                            ),
                                          ),
                                          TextSpan(
                                            text: '/${msg.totalToSend}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              else if (msg.isCanceled)
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Canceled ',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      TextSpan(
                                        text: '${msg.currentSent}',
                                        style: const TextStyle(
                                          color: Color(0xFFFBB03B),
                                        ),
                                      ),
                                      const TextSpan(
                                        text: '/',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      TextSpan(
                                        text: '${msg.totalToSend}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (msg.isCompleted) // Check isCompleted
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Sent ',
                                        style: TextStyle(
                                          color: Color(0xFFFBB03B),
                                        ),
                                      ),
                                      TextSpan(
                                        text: '${msg.currentSent}',
                                        style: const TextStyle(
                                          color: Color(0xFFFBB03B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '/${msg.totalToSend}',
                                        style: const TextStyle(
                                          color: Color(0xFFFBB03B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Sending... ',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      TextSpan(
                                        text: '${msg.currentSent}',
                                        style: const TextStyle(
                                          color: Color(0xFFFBB03B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '/${msg.totalToSend}',
                                        style: TextStyle(
                                          color: Colors
                                              .grey
                                              .shade600, // Total grey
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),

        // Message Input Area
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Send a message...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBB03B), // Brand yellow
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
