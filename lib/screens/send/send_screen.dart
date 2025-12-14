import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/sms_service.dart';
import '../../providers/contacts_provider.dart';

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

class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final Map<String, StreamSubscription> _subscriptions =
      {}; // Track active streams

  // Chip state

  @override
  void dispose() {
    _recipientController.dispose();
    _messageController.dispose();
    // Cancel all subscriptions
    for (var sub in _subscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final smsService = SmsService();
    final granted = await smsService.requestPermissions();
    if (granted != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SMS permissions are required to send messages.'),
        ),
      );
      return;
    }

    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    // 1. Gather Recipients
    final List<String> targetPhoneNumbers = [];

    // Check for manual entry
    final manualRecipient = _recipientController.text.trim();
    if (manualRecipient.isNotEmpty) {
      targetPhoneNumbers.add(manualRecipient);
    }

    // Gather all contacts from DB
    final contacts = ref.read(contactsProvider);
    targetPhoneNumbers.addAll(contacts.map((c) => c.phone));

    // De-duplicate
    final uniqueRecipients = targetPhoneNumbers.toSet().toList();

    if (uniqueRecipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recipients selected/found.')),
      );
      return;
    }

    final newMessage = Message(
      id: DateTime.now().toString(),
      text: text,
      timestamp: DateTime.now(),
      currentSent: 0,
      totalToSend: uniqueRecipients.length,
    );

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
      // Optional: Clear recipient field if used? Maybe keep it.
    });

    // 2. Start Sending via Service
    final stream = smsService.sendBatchSms(
      recipients: uniqueRecipients,
      message: text,
      delay: const Duration(milliseconds: 1000), // 1 sec delay for safety
    );

    _subscriptions[newMessage.id] = stream.listen(
      (count) {
        if (!mounted) return;
        setState(() {
          newMessage.currentSent = count;
          if (newMessage.currentSent >= newMessage.totalToSend) {
            newMessage.isCompleted = true;
            _subscriptions[newMessage.id]?.cancel();
            _subscriptions.remove(newMessage.id);
          }
        });
      },
      onError: (e) {
        debugPrint("Error sending batch: $e");
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          // Ensure marked complete if stream finishes
          if (newMessage.currentSent < newMessage.totalToSend) {
            // Maybe some failed?
            // For now, let's assume done means done.
          }
          newMessage.isCompleted = true;
          _subscriptions.remove(newMessage.id);
        });
      },
    );
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
                  // Cancel the subscription if active
                  _subscriptions[msg.id]?.cancel();
                  _subscriptions.remove(msg.id);
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
    // Ensure contacts are loaded
    ref.watch(contactsProvider);

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
