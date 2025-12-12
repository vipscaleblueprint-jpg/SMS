import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/queued_message.dart';

class QueueNotifier extends Notifier<List<QueuedMessage>> {
  @override
  List<QueuedMessage> build() {
    return [];
  }

  void addToQueue(QueuedMessage message) {
    state = [...state, message];
  }

  void updateMessageStatus(String id, MessageStatus status) {
    state = [
      for (final msg in state)
        if (msg.id == id) msg.copyWith(status: status) else msg,
    ];
  }

  void removeFromQueue(String id) {
    state = state.where((msg) => msg.id != id).toList();
  }
}

final queueProvider = NotifierProvider<QueueNotifier, List<QueuedMessage>>(
  QueueNotifier.new,
);
