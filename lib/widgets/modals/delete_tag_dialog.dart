import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tag.dart';
import '../../providers/tags_provider.dart';

class DeleteTagDialog extends ConsumerWidget {
  final Tag tag;
  const DeleteTagDialog({super.key, required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    'Delete Tag',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Are you sure you want to delete "${tag.name}"? This action cannot be undone.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      height: 1.3,
                      color: Colors.black,
                    ),
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
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      ref.read(tagsProvider.notifier).removeTag(tag.id);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Color(0xFFFF3B30), // iOS Red
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
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
