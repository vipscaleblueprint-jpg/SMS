import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../widgets/list/dropdown-contacts.dart';
import '../../providers/send_message_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../widgets/header_user.dart';

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
  bool _isSyncing = false;
  bool _isFirstLoad = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncExternalContacts(silent: true);
    });
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _messageController.dispose();
    _recipientFocusNode.dispose();
    // Subscriptions handled in provider
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    try {
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
      final sendState = ref.read(sendMessageProvider);

      // Validation
      if (text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a message.')),
        );
        return;
      }

      if (sendState.selectedContactIds.isEmpty &&
          sendState.selectedTagIds.isEmpty &&
          manualRecipient.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No recipients selected.')),
        );
        return;
      }

      // Show Dialog for Schedule or Instant
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Send Message'),
            content: const Text('When would you like to send this message?'),
            actions: [
              TextButton(
                onPressed: () async {
                  // Save the main context before closing dialog
                  final mainContext = context;
                  Navigator.of(dialogContext).pop();

                  // Use the saved context for pickers
                  if (!mounted) return;

                  DateTime? pickedDate = await showDatePicker(
                    context: mainContext,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          datePickerTheme: const DatePickerThemeData(
                            backgroundColor: Colors.white,
                            surfaceTintColor: Colors.transparent,
                            headerBackgroundColor: Color(0xFFFFF0D6),
                            headerForegroundColor: Colors.black,
                          ),
                          timePickerTheme: const TimePickerThemeData(
                            backgroundColor: Colors.white,
                          ),
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFFFBB03B),
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                            surface: Colors.white,
                            surfaceContainerHigh: Colors.white,
                          ),
                          dialogBackgroundColor: Colors.white,
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (pickedDate != null && mounted) {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: mainContext,
                      initialTime: TimeOfDay.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            timePickerTheme: const TimePickerThemeData(
                              backgroundColor: Colors.white,
                              hourMinuteColor: Color(0xFFFFF0D6),
                              dayPeriodColor: Color(0xFFFFF0D6),
                              dialHandColor: Color(0xFFFBB03B),
                              dialBackgroundColor: Colors.white,
                            ),
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFFFBB03B),
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                              surface: Colors.white,
                              surfaceContainerHigh: Colors.white,
                              surfaceContainerHighest: Colors.white,
                            ),
                            dialogBackgroundColor: Colors.white,
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (pickedTime != null && mounted) {
                      final scheduledTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                      _executeSend(
                        text,
                        manualRecipient,
                        instant: false,
                        scheduledTime: scheduledTime,
                      );
                    }
                  }
                },
                child: const Text('Schedule'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _executeSend(text, manualRecipient, instant: true);
                },
                child: const Text('Instant'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error in _sendMessage: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _executeSend(
    String text,
    String manualRecipient, {
    bool instant = true,
    DateTime? scheduledTime,
  }) async {
    final notifier = ref.read(sendMessageProvider.notifier);
    await notifier.sendBatch(
      text: text,
      manualRecipient: manualRecipient,
      instant: instant,
      scheduledTime: scheduledTime,
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
    _recipientController.clear();
    notifier.clearRecipients();
    FocusScope.of(context).unfocus();
  }

  Future<void> _syncExternalContacts({bool silent = false}) async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final count = await ref
          .read(contactsProvider.notifier)
          .fetchAndSaveExternalContacts();
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully synced $count contacts.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent || !_isFirstLoad) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error syncing contacts: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _isFirstLoad = false;
        });
      }
    }
  }

  void _toggleStopButton(String id) {
    ref.read(sendMessageProvider.notifier).toggleStopButton(id);
  }

  void _showStopConfirmationDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeaderUser(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Message',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withOpacity(0.85),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Select recipients and compose',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (_isSyncing)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBB03B).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFBB03B),
                          ),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: _syncExternalContacts,
                      tooltip: 'Sync Contacts',
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBB03B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.sync_rounded,
                          color: Color(0xFFFBB03B),
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

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
            color: const Color(0xFFF8F9FA), // Professional off-white
            width: double.infinity,
            child: messages.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    reverse: true,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(4),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.text,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.5,
                                        color: Colors.black.withOpacity(0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (msg.scheduledTime != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today_rounded,
                                                size: 12,
                                                color: Color(0xFFFBB03B),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat(
                                                  'MMM dd, hh:mm a',
                                                ).format(msg.scheduledTime!),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFFFBB03B),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          const SizedBox.shrink(),
                                        Text(
                                          timeStr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade400,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Sending Status / Stop UI
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: _buildEnhancedStatus(msg),
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
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: 5,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Send a message...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBB03B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBB03B).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedStatus(Message msg) {
    if (msg.isStopButtonVisible) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${msg.currentSent}',
                style: const TextStyle(
                  color: Color(0xFFFBB03B),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                ' / ${msg.totalToSend} sending',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showStopConfirmationDialog(msg.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Stop',
                    style: TextStyle(
                      color: Color(0xFFFF5252),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (msg.isCanceled) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            'Canceled (${msg.currentSent}/${msg.totalToSend})',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (msg.isCompleted) {
      final isScheduledQueue = msg.scheduledTime != null && !msg.isSent;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isScheduledQueue
                ? Icons.access_time_filled_rounded
                : Icons.check_circle_rounded,
            size: 14,
            color: const Color(0xFFFBB03B),
          ),
          const SizedBox(width: 4),
          Text(
            isScheduledQueue
                ? 'Scheduled (queued)'
                : 'Sent to all ${msg.totalToSend}',
            style: const TextStyle(
              color: Color(0xFFFBB03B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Sending ${msg.currentSent}/${msg.totalToSend}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
