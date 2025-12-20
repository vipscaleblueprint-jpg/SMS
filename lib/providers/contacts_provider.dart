import 'dart:convert';
import 'package:http/http.dart' as http;
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

  Future<int> fetchAndSaveExternalContacts() async {
    final response = await http.get(
      Uri.parse(
        'https://n8n.srv1151765.hstgr.cloud/webhook/2f19e860-892f-45ba-8143-96a0c420c71d',
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final List<Contact> fetchedContacts = data.map((item) {
        return Contact(
          contact_id: item['id'] as String,
          first_name: item['first_name'] as String? ?? '',
          last_name:
              item['lsat_name'] as String? ??
              '', // Note the 'lsat_name' typo in API
          email: item['email'] as String?,
          phone: item['phone'] as String? ?? '',
          created: DateTime.now(),
        );
      }).toList();

      for (final contact in fetchedContacts) {
        await _db.insertContact(contact);
      }
      await _loadContacts();
      return fetchedContacts.length;
    } else {
      throw Exception('Failed to fetch contacts: ${response.statusCode}');
    }
  }

  // =========================
  // UPDATE (future-ready)
  // =========================

  Future<void> updateContact(Contact contact) async {
    await _db.updateContact(contact);
    await _loadContacts();
  }

  // =========================
  // DELETE
  // =========================

  Future<void> deleteContact(String id) async {
    await _db.deleteContact(id);
    await _loadContacts();
  }

  Future<void> removeContact(String id) async {
    await deleteContact(id);
  }

  Future<void> deleteContacts(List<String> ids) async {
    for (final id in ids) {
      await _db.deleteContact(id);
    }
    await _loadContacts();
  }

  // =========================
  // CLEAR
  // =========================

  void clear() {
    state = [];
  }
}

final contactsProvider = NotifierProvider<ContactsNotifier, List<Contact>>(
  ContactsNotifier.new,
);
