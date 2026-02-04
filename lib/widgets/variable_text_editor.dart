import 'package:flutter/material.dart';

class VariableTextEditor extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Map<String, String> variables;

  const VariableTextEditor({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    this.variables = const {
      'First Name': '{{first_name}}',
      'Last Name': '{{last_name}}',
      'Full Name': '{{full_name}}',
      'Your Name': '{{your_name}}',
    },
  });

  @override
  State<VariableTextEditor> createState() => _VariableTextEditorState();
}

class _VariableTextEditorState extends State<VariableTextEditor> {
  TextSelection _lastSelection = const TextSelection.collapsed(offset: -1);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleSelectionChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleSelectionChanged);
    super.dispose();
  }

  void _handleSelectionChanged() {
    final selection = widget.controller.selection;
    if (selection.isValid) {
      _lastSelection = selection;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            // Add Customization Button
            PopupMenuButton<String>(
              color: Colors.white,
              surfaceTintColor: Colors.white,
              onSelected: (value) {
                final placeholder = widget.variables[value] ?? '';
                if (placeholder.isNotEmpty) {
                  final text = widget.controller.text;

                  // Use _lastSelection if valid, otherwise try current controller selection
                  TextSelection selection = _lastSelection;
                  if (!selection.isValid) {
                    selection = widget.controller.selection;
                  }

                  int start = selection.start;
                  int end = selection.end;

                  // Safety checks for bounds
                  if (start < 0 || start > text.length) start = text.length;
                  if (end < 0 || end > text.length) end = text.length;
                  if (end < start) end = start;

                  final newText = text.replaceRange(start, end, placeholder);

                  widget.controller.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(
                      offset: start + placeholder.length,
                    ),
                  );

                  // Restore focus
                  widget.focusNode.requestFocus();
                }
              },
              itemBuilder: (BuildContext context) {
                return widget.variables.keys.map((String key) {
                  return PopupMenuItem<String>(value: key, child: Text(key));
                }).toList();
              },
              offset: const Offset(0, 40),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBB03B),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: const Text(
                  'Add Customization',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            maxLines: 15,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }
}
