import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact.dart';

class ContactsNotifier extends Notifier<List<Contact>> {
  @override
  List<Contact> build() {
    return [];
  }

  void addContact(Contact contact) {
    state = [...state, contact];
  }

  void addContacts(List<Contact> contacts) {
    state = [...state, ...contacts];
  }

  void removeContact(String id) {
    state = state.where((c) => c.contact_id != id).toList();
  }

  void updateContact(Contact contact) {
    state = [
      for (final c in state)
        if (c.contact_id == contact.contact_id) contact else c,
    ];
  }
}

final contactsProvider = NotifierProvider<ContactsNotifier, List<Contact>>(
  ContactsNotifier.new,
);
