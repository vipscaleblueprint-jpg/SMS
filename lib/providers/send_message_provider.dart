import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sms_service.dart';
import 'contacts_provider.dart';

// Message Model
class Message {
  final String id;
  final String text;
  final DateTime timestamp;
  int currentSent;
  final int totalToSend;
  bool isStopButtonVisible;
  bool isCanceled;
  bool isCompleted;

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    this.currentSent = 0,
    this.totalToSend = 0,
    this.isStopButtonVisible = false,
    this.isCanceled = false,
    this.isCompleted = false,
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

  @override
  SendMessageState build() {
    // Return initial state
    ref.onDispose(() {
      // Cancel subscriptions on dispose
      for (var sub in _subscriptions.values) {
        sub.cancel();
      }
    });
    return SendMessageState();
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
  Future<void> sendBatch({
    required String text,
    String? manualRecipient,
    required Function(String) onError,
    required VoidCallback onRecipientsEmpty,
  }) async {
    if (text.trim().isEmpty) return;

    final targetPhoneNumbers = <String>[];
    final allContacts = ref.read(contactsProvider);

    // Tags
    if (state.selectedTagIds.isNotEmpty) {
      for (final contact in allContacts) {
        if (contact.tags.any((tag) => state.selectedTagIds.contains(tag.id))) {
          targetPhoneNumbers.add(contact.phone);
        }
      }
    }

    // Contacts
    if (state.selectedContactIds.isNotEmpty) {
      for (final contact in allContacts) {
        if (state.selectedContactIds.contains(contact.contact_id)) {
          targetPhoneNumbers.add(contact.phone);
        }
      }
    }

    // Manual Recipient
    if (state.selectedContactIds.isEmpty &&
        state.selectedTagIds.isEmpty &&
        manualRecipient != null &&
        manualRecipient.isNotEmpty) {
      targetPhoneNumbers.add(manualRecipient);
    }

    final uniqueRecipients = targetPhoneNumbers.toSet().toList();

    if (uniqueRecipients.isEmpty) {
      onRecipientsEmpty();
      return;
    }

    final newMessage = Message(
      id: DateTime.now().toString(),
      text: text,
      timestamp: DateTime.now(),
      currentSent: 0,
      totalToSend: uniqueRecipients.length,
    );

    // Update state to include new message
    state = state.copyWith(messages: [...state.messages, newMessage]);

    final stream = _smsService.sendBatchSms(
      recipients: uniqueRecipients,
      message: text,
      delay: const Duration(milliseconds: 1000),
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
