import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tag.dart';
import '../../providers/tags_provider.dart';

class EditTagDialog extends ConsumerStatefulWidget {
  final Tag tag;
  const EditTagDialog({super.key, required this.tag});

  @override
  ConsumerState<EditTagDialog> createState() => _EditTagDialogState();
}

class _EditTagDialogState extends ConsumerState<EditTagDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tag.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Colors.white,
      child: SizedBox(
        width: 270, // Approximate standard iOS dialog width
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 20.0,
                bottom: 20.0,
                left: 16.0,
                right: 16.0,
              ),
              child: Column(
                children: [
                  const Text(
                    'Edit Tag',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Tag Name',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFFBB03B),
                          width: 1,
                        ),
                      ),
                    ),
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            const Divider(height: 0.5, thickness: 0.5, color: Colors.grey),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF007AFF), // iOS Blue
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      final newName = _controller.text.trim();
                      if (newName.isNotEmpty && newName != widget.tag.name) {
                        ref
                            .read(tagsProvider.notifier)
                            .updateTag(widget.tag.copyWith(name: newName));
                      }
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Color(0xFF007AFF), // iOS Blue
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
