import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact.dart';
import '../utils/db/contact_db_helper.dart';

class ContactsNotifier extends Notifier<List<Contact>> {
  final _db = ContactDbHelper.instance;

  @override
  List<Contact> build() {
    _loadContacts();
    return [];
  }

  // =========================
  // LOAD
  // =========================

  Future<void> _loadContacts() async {
    final contacts = await _db.getAllContacts();
    state = contacts;
  }

  // =========================
  // ADD
  // =========================

  Future<void> addContact(Contact contact) async {
    await _db.insertContact(contact);
    await _loadContacts();
  }

  Future<void> addContacts(List<Contact> contacts) async {
    for (final contact in contacts) {
      await _db.insertContact(contact);
    }
    await _loadContacts();
  }

  // =========================
  // UPDATE (future-ready)
  // =========================

  Future<void> updateContact(Contact contact) async {
    // SQLite uses REPLACE → insert again
    await _db.insertContact(contact);
    await _loadContacts();
  }

  // =========================
  // DELETE
  // =========================

  Future<void> removeContact(String id) async {
    await _db.deleteContact(id);
    await _loadContacts();
  }
}

final contactsProvider = NotifierProvider<ContactsNotifier, List<Contact>>(
  ContactsNotifier.new,
);
