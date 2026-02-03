import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import '../models/contact.dart';
import '../models/tag.dart';

class CsvService {
  Future<List<Contact>> importContactsFromCsv(File file) async {
    final input = await file.readAsString();
    return parseCsvContent(input);
  }

  List<Contact> parseCsvContent(String input) {
    // We'll try to detect the delimiter.
    String delimiter = ',';
    if (input.contains('\t')) {
      delimiter = '\t';
    } else if (input.contains(';')) {
      delimiter = ';';
    }

    debugPrint('🔵 Detected CSV delimiter: "$delimiter"');

    // Convert
    List<List<dynamic>> rows = CsvToListConverter(
      fieldDelimiter: delimiter,
    ).convert(input, eol: '\n');

    // Fallback for EOL if converter failed to split lines correctly
    if (rows.length <= 1 && input.contains('\r\n')) {
      rows = CsvToListConverter(
        fieldDelimiter: delimiter,
      ).convert(input, eol: '\r\n');
    }

    if (rows.isEmpty) return [];

    // Header matching - strictly based on user provided sample
    // Contact Id, First Name, Last Name, Name, Phone, Email, Created, Last Activity, Tags
    final header = rows.first
        .map((e) => e.toString().toLowerCase().trim())
        .toList();

    int contactIdIdx = header.indexWhere(
      (h) => h.contains('id') && h.contains('contact'),
    );
    int firstNameIdx = header.indexWhere(
      (h) => h == 'first name' || h == 'firstname' || h == 'first',
    );
    int lastNameIdx = header.indexWhere(
      (h) =>
          h == 'last name' || h == 'lastname' || h == 'last' || h == 'surname',
    );
    int nameIdx = header.indexWhere(
      (h) => h == 'name' || h == 'full name' || h == 'fullname',
    );
    int phoneIdx = header.indexWhere(
      (h) =>
          h.contains('phone') ||
          h.contains('mobile') ||
          h.contains('cell') ||
          h.contains('number'),
    );
    int emailIdx = header.indexWhere(
      (h) => h.contains('email') || h.contains('e-mail'),
    );
    int createdIdx = header.indexWhere(
      (h) => h == 'created' || h == 'date' || h.contains('created'),
    );
    int tagsIdx = header.indexWhere(
      (h) => h == 'tags' || h == 'tag' || h.contains('label'),
    );

    List<Contact> contacts = [];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      // Helper to safely get value
      String getVal(int idx) {
        if (idx != -1 && idx < row.length) {
          return row[idx].toString().trim();
        }
        return '';
      }

      String contactId = getVal(contactIdIdx);
      if (contactId.isEmpty) {
        contactId =
            DateTime.now().microsecondsSinceEpoch.toString() + i.toString();
      }

      String firstName = getVal(firstNameIdx);
      String lastName = getVal(lastNameIdx);
      // Fallback
      if (firstName.isEmpty && lastName.isEmpty) {
        final fullName = getVal(nameIdx);
        if (fullName.isNotEmpty) {
          // Simple split
          final parts = fullName.split(' ');
          if (parts.length > 1) {
            firstName = parts.first;
            lastName = parts.sublist(1).join(' ');
          } else {
            firstName = fullName;
          }
        }
      }

      String phone = getVal(phoneIdx);

      // Handle scientific notation
      if (phone.contains('E+') || phone.contains('e+')) {
        try {
          double d = double.parse(phone);
          phone = d.toStringAsFixed(0);
        } catch (e) {
          // keep original
        }
      }

      String? email = getVal(emailIdx);
      if (email.isEmpty) email = null;

      DateTime created = DateTime.now();
      String createdStr = getVal(createdIdx);
      if (createdStr.isNotEmpty) {
        try {
          created = DateTime.parse(createdStr);
        } catch (_) {
          // fallback
        }
      }

      List<Tag> tags = [];
      String tagsRaw = getVal(tagsIdx);
      if (tagsRaw.isNotEmpty) {
        tags = tagsRaw
            .split(',')
            .map(
              (tName) => Tag(
                id: 'csv_${DateTime.now().millisecondsSinceEpoch}_${tName.trim().hashCode}',
                name: tName.trim(),
                created: DateTime.now(),
              ),
            )
            .toList();
      }

      contacts.add(
        Contact(
          contact_id: contactId,
          first_name: firstName,
          last_name: lastName,
          phone: phone,
          email: email,
          created: created,
          tags: tags,
        ),
      );
    }

    return contacts;
  }
}
