import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sms_service.dart';
import 'contacts_provider.dart';
import 'user_provider.dart';
import 'tags_provider.dart';
import '../models/contact.dart';
import '../models/sms.dart';
import '../utils/db/sms_db_helper.dart';

// Message Model
class Message {
  final String id;
  final String text;
  final DateTime timestamp;
  final DateTime? scheduledTime; // When the message is scheduled to send
  int currentSent;
  final int totalToSend;
  bool isStopButtonVisible;
  bool isCanceled;
  bool isCompleted;
  bool isSent;

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    this.scheduledTime,
    this.currentSent = 0,
    this.totalToSend = 0,
    this.isStopButtonVisible = false,
    this.isCanceled = false,
    this.isCompleted = false,
    this.isSent = false,
  });
}

// State Class
class SendMessageState {
  final Set<String> selectedContactIds;
  final Set<String> selectedTagIds;
  final List<Message> messages;
  final bool isSending;

  SendMessageState({
    this.selectedContactIds = const {},
    this.selectedTagIds = const {},
    this.messages = const [],
    this.isSending = false,
  });

  SendMessageState copyWith({
    Set<String>? selectedContactIds,
    Set<String>? selectedTagIds,
    List<Message>? messages,
    bool? isSending,
  }) {
    return SendMessageState(
      selectedContactIds: selectedContactIds ?? this.selectedContactIds,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}

// Notifier
class SendMessageNotifier extends Notifier<SendMessageState> {
  final SmsService _smsService = SmsService();
  final Map<String, StreamSubscription> _subscriptions = {};
  Timer? _refreshTimer;

  @override
  SendMessageState build() {
    // Return initial state
    ref.onDispose(() {
      // Cancel subscriptions on dispose
      for (var sub in _subscriptions.values) {
        sub.cancel();
      }
      _refreshTimer?.cancel();
    });

    // Load history asynchronously
    _loadHistory();

    // Set up periodic refresh to catch background status changes
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadHistory();
    });

    return SendMessageState();
  }

  Future<void> _loadHistory() async {
    final history = await SmsDbHelper().getGroupedSmsHistory();
    final uiMessages = history
        .map(
          (s) => Message(
            id: s.batchId ?? s.id?.toString() ?? DateTime.now().toString(),
            text: s.message,
            timestamp: s.sentTimeStamps ?? s.schedule_time ?? DateTime.now(),
            scheduledTime: s.schedule_time,
            currentSent: s.status == SmsStatus.sent ? (s.batchTotal ?? 1) : 0,
            totalToSend: s.batchTotal ?? 1,
            isCompleted:
                s.status == SmsStatus.sent || s.status == SmsStatus.pending,
            isSent: s.status == SmsStatus.sent,
          ),
        )
        .toList();

    // Sort Newest -> Oldest (Index 0 = Newest)
    uiMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Preserve active sending state for messages currently being processed
    final finalMessages = uiMessages.map((newMsg) {
      final activeIndex = state.messages.indexWhere((m) => m.id == newMsg.id);
      if (activeIndex != -1 && _subscriptions.containsKey(newMsg.id)) {
        return state.messages[activeIndex];
      }
      return newMsg;
    }).toList();

    state = state.copyWith(messages: finalMessages);
  }

  void toggleContact(String contactId) {
    final currentIds = Set<String>.from(state.selectedContactIds);
    if (currentIds.contains(contactId)) {
      currentIds.remove(contactId);
    } else {
      currentIds.add(contactId);
    }
    state = state.copyWith(selectedContactIds: currentIds);
  }

  void toggleTag(String tagId) {
    final currentIds = Set<String>.from(state.selectedTagIds);
    if (currentIds.contains(tagId)) {
      currentIds.remove(tagId);
    } else {
      currentIds.add(tagId);
    }
    state = state.copyWith(selectedTagIds: currentIds);
  }

  void clearRecipients() {
    state = state.copyWith(selectedContactIds: {}, selectedTagIds: {});
  }

  // Returns true if permissions granted, false otherwise.
  Future<bool> requestPermissions() async {
    final result = await _smsService.requestPermissions();
    return result ?? false;
  }

  // Send Batch Logic
  // Send Batch Logic
  Future<void> sendBatch({
    required String text,
    String? manualRecipient,
    required Function(String) onError,
    required VoidCallback onRecipientsEmpty,
    bool instant = true,
    DateTime? scheduledTime,
    int simSlot = 1,
  }) async {
    if (text.trim().isEmpty) return;

    final targetContacts = <Contact>[];
    final allContacts = ref.read(contactsProvider);

    // Helper to avoid duplicates by ID
    final addedContactIds = <String>{};

    // Tags
    if (state.selectedTagIds.isNotEmpty) {
      for (final contact in allContacts) {
        if (!addedContactIds.contains(contact.contact_id) &&
            contact.tags.any((tag) => state.selectedTagIds.contains(tag.id))) {
          targetContacts.add(contact);
          addedContactIds.add(contact.contact_id);
        }
      }
    }

    // Contacts
    if (state.selectedContactIds.isNotEmpty) {
      for (final contact in allContacts) {
        if (!addedContactIds.contains(contact.contact_id) &&
            state.selectedContactIds.contains(contact.contact_id)) {
          targetContacts.add(contact);
          addedContactIds.add(contact.contact_id);
        }
      }
    }

    // Manual Recipient (Create and save contact with 'new' tag)
    if (manualRecipient != null && manualRecipient.trim().isNotEmpty) {
      final newTag = await ref
          .read(tagsProvider.notifier)
          .getOrCreateTag('new');

      final manualContact = Contact(
        contact_id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        first_name: 'Manual',
        last_name: 'Recipient',
        phone: manualRecipient.trim(),
        created: DateTime.now(),
        tags: [newTag],
      );

      // Save to database
      await ref.read(contactsProvider.notifier).addContact(manualContact);

      targetContacts.add(manualContact);
      addedContactIds.add(manualContact.contact_id);
    }

    if (targetContacts.isEmpty) {
      debugPrint('⚠️ sendBatch: targetContacts is EMPTY');
      onRecipientsEmpty();
      return;
    }

    debugPrint('🚀 sendBatch: starting for ${targetContacts.length} contacts');
    debugPrint('🚀 First contact phone: ${targetContacts.first.phone}');

    final newMessage = Message(
      id: DateTime.now().toString(),
      text: text,
      timestamp: DateTime.now(),
      scheduledTime: scheduledTime,
      currentSent: 0,
      totalToSend: targetContacts.length,
    );

    // Update state to include new message at the BEGINNING (Index 0)
    // Because ListView is reversed: Index 0 => Bottom
    state = state.copyWith(messages: [newMessage, ...state.messages]);

    // Fetch sender name for variable resolution
    final user = ref.read(userProvider);
    final senderName = user.name;

    final stream = _smsService.sendBatchSmsWithDetails(
      contacts: targetContacts,
      message: text,
      instant: instant,
      scheduledTime: scheduledTime,
      simSlot: simSlot,
      delay: const Duration(milliseconds: 1000),
      senderName: senderName,
    );

    _subscriptions[newMessage.id] = stream.listen(
      (count) {
        _updateMessageProgress(newMessage.id, count);
      },
      onError: (e) {
        debugPrint("Error sending batch: $e");
        onError(e.toString());
      },
      onDone: () {
        _completeMessage(newMessage.id);
      },
    );
  }

  void _updateMessageProgress(String id, int count) {
    final messages = [...state.messages];
    final index = messages.indexWhere((m) => m.id == id);
    if (index != -1) {
      messages[index].currentSent = count;
      if (messages[index].currentSent >= messages[index].totalToSend) {
        messages[index].isCompleted = true;
        _subscriptions[id]?.cancel();
        _subscriptions.remove(id);
      }
      state = state.copyWith(messages: messages);
    }
  }

  void _completeMessage(String id) {
    final messages = [...state.messages];
    final index = messages.indexWhere((m) => m.id == id);
    if (index != -1) {
      messages[index].isCompleted = true;
      messages[index].isSent = true;
      // Cleanup subscription
      _subscriptions[id]?.cancel();
      _subscriptions.remove(id);
      state = state.copyWith(messages: messages);
    }
  }

  void toggleStopButton(String id) {
    final messages = [...state.messages];
    final index = messages.indexWhere((m) => m.id == id);
    if (index != -1) {
      final msg = messages[index];
      if (msg.isCanceled || msg.isCompleted) return;

      msg.isStopButtonVisible = !msg.isStopButtonVisible;
      state = state.copyWith(messages: messages);
    }
  }

  void stopSending(String id) {
    final messages = [...state.messages];
    final index = messages.indexWhere((m) => m.id == id);
    if (index != -1) {
      messages[index].isCanceled = true;
      messages[index].isStopButtonVisible = false;
      _subscriptions[id]?.cancel();
      _subscriptions.remove(id);
      state = state.copyWith(messages: messages);
    }
  }
}

final sendMessageProvider =
    NotifierProvider<SendMessageNotifier, SendMessageState>(
      SendMessageNotifier.new,
    );
