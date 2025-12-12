import 'dart:io';
import 'package:csv/csv.dart';
import '../models/contact.dart';
import '../models/tag.dart';

class CsvService {
  Future<List<Contact>> importContactsFromCsv(File file) async {
    final input = await file.readAsString();
    
    // The sample provided is likely Tab-Separated Values (TSV) or could be CSV.
    // We'll try to detect the delimiter.
    String delimiter = ',';
    if (input.contains('\t')) {
      delimiter = '\t';
    }

    // Convert
    List<List<dynamic>> rows = CsvToListConverter(fieldDelimiter: delimiter).convert(input, eol: '\n');
    
    // Fallback for EOL if converter failed to split lines correctly
    if (rows.length <= 1 && input.contains('\r\n')) {
       rows = CsvToListConverter(fieldDelimiter: delimiter).convert(input, eol: '\r\n');
    }

    if (rows.isEmpty) return [];

    // Header matching - strictly based on user provided sample
    // Contact Id, First Name, Last Name, Name, Phone, Email, Created, Last Activity, Tags
    final header = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
    
    int contactIdIdx = header.indexOf('contact id');
    int firstNameIdx = header.indexOf('first name');
    int lastNameIdx = header.indexOf('last name');
    int nameIdx = header.indexOf('name');
    int phoneIdx = header.indexOf('phone');
    int emailIdx = header.indexOf('email');
    int createdIdx = header.indexOf('created'); 
    int tagsIdx = header.indexOf('tags');

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
         contactId = DateTime.now().microsecondsSinceEpoch.toString() + i.toString();
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
        tags = tagsRaw.split(',').map((tName) => Tag(
          id: tName.trim(), 
          name: tName.trim(),
          created: DateTime.now()
        )).toList();
      }

      contacts.add(Contact(
        contact_id: contactId,
        first_name: firstName,
        last_name: lastName,
        phone: phone,
        email: email,
        created: created,
        tags: tags,
      ));
    }

    return contacts;
  }
}
