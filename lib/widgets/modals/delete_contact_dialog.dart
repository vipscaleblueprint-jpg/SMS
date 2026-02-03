import 'package:flutter/material.dart';
import 'delete_confirmation_dialog.dart';

class DeleteContactDialog extends StatelessWidget {
  final String contactName;

  const DeleteContactDialog({super.key, required this.contactName});

  @override
  Widget build(BuildContext context) {
    return DeleteConfirmationDialog(
      title: 'Are you sure you want to\ndelete this contact?',
      message:
          '', // Message is empty as per original design for contact deletion
    );
  }
}
