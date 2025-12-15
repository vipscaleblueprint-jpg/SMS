import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/list/dropdown-contacts.dart';
import '../../providers/send_message_provider.dart';

// Message class moved to provider

class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  // Recipient dropdown state managed by DropdownContacts now
  final FocusNode _recipientFocusNode = FocusNode();

  void dispose() {
    _recipientController.dispose();
    _messageController.dispose();
    _recipientFocusNode.dispose();
    // Subscriptions handled in provider
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final notifier = ref.read(sendMessageProvider.notifier);
    final granted = await notifier.requestPermissions();

    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SMS permissions are required to send messages.'),
        ),
      );
      return;
    }

    final text = _messageController.text;
    final manualRecipient = _recipientController.text.trim();

    await notifier.sendBatch(
      text: text,
      manualRecipient: manualRecipient,
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $error')));
      },
      onRecipientsEmpty: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No recipients selected.')),
        );
      },
    );

    _messageController.clear();
    notifier.clearRecipients();
    FocusScope.of(context).unfocus();
    // Use setState only if strictly needed for local UI unrelated to provider, but provider updates will rebuild
  }

  void _toggleStopButton(String id) {
    ref.read(sendMessageProvider.notifier).toggleStopButton(id);
  }

  void _showStopConfirmationDialog(String id) {
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
                ref.read(sendMessageProvider.notifier).stopSending(id);
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

  // Dropdown methods removed (moved to DropdownContacts)

  @override
  Widget build(BuildContext context) {
    // Watch state
    final sendState = ref.watch(sendMessageProvider);
    final messages = sendState.messages;

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

              DropdownContacts(
                controller: _recipientController,
                focusNode: _recipientFocusNode,
                selectedContactIds: sendState.selectedContactIds,
                selectedTagIds: sendState.selectedTagIds,
                onContactSelected: (contact) {
                  ref
                      .read(sendMessageProvider.notifier)
                      .toggleContact(contact.contact_id);
                },
                onTagSelected: (tag) {
                  ref.read(sendMessageProvider.notifier).toggleTag(tag.id);
                },
              ),
            ],
          ),
        ),

        // Central Content Area (Message List)
        Expanded(
          child: Container(
            color: const Color(0xFFE0E0E0), // Light grey placeholder
            width: double.infinity,
            child: messages.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      // Display nicely with time formatting
                      final timeStr =
                          "${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')} ${msg.timestamp.hour >= 12 ? 'pm' : 'am'}";

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: GestureDetector(
                          onLongPress: () => _toggleStopButton(msg.id),
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
                                            _showStopConfirmationDialog(msg.id),
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
