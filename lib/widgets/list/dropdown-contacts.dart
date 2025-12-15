import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/tags_provider.dart';
import '../../models/contact.dart';
import '../../models/tag.dart';

class DropdownContacts extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Set<String> selectedContactIds;
  final Set<String> selectedTagIds;
  final Function(Contact) onContactSelected;
  final Function(Tag) onTagSelected;

  const DropdownContacts({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.selectedContactIds,
    required this.selectedTagIds,
    required this.onContactSelected,
    required this.onTagSelected,
  });

  @override
  ConsumerState<DropdownContacts> createState() => _DropdownContactsState();
}

class _DropdownContactsState extends ConsumerState<DropdownContacts> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _dropdownOverlay;
  final String _tapRegionGroupId = 'dropdown_contacts_group';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(DropdownContacts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedContactIds != oldWidget.selectedContactIds ||
        widget.selectedTagIds != oldWidget.selectedTagIds) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _dropdownOverlay != null) {
          _dropdownOverlay!.markNeedsBuild();
        }
      });
    }
  }

  @override
  void dispose() {
    _removeDropdown();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;
    if (_dropdownOverlay != null) {
      _dropdownOverlay!.markNeedsBuild();
    } else if (widget.focusNode.hasFocus && widget.controller.text.isNotEmpty) {
      _showDropdown();
    }
  }

  void _removeDropdown() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
  }

  void _showDropdown() {
    if (!mounted) return;
    if (_dropdownOverlay != null) return;

    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;

    final overlay = Overlay.of(context);
    final renderBox = renderObject as RenderBox;
    final size = renderBox.size;

    _dropdownOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 5),
          child: TapRegion(
            groupId: _tapRegionGroupId,
            child: _RecipientList(
              searchText: widget.controller.text,
              selectedContactIds: widget.selectedContactIds,
              selectedTagIds: widget.selectedTagIds,
              onContactSelected: (contact) {
                widget.onContactSelected(contact);
                _dropdownOverlay?.markNeedsBuild();
              },
              onTagSelected: (tag) {
                widget.onTagSelected(tag);
                _dropdownOverlay?.markNeedsBuild();
              },
            ),
          ),
        ),
      ),
    );

    overlay.insert(_dropdownOverlay!);
  }

  void _toggleDropdown() {
    if (_dropdownOverlay != null) {
      _removeDropdown();
    } else {
      widget.focusNode.requestFocus();
      _showDropdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers to get actual data for chips
    final allContacts = ref.watch(contactsProvider);
    final allTags = ref.watch(tagsProvider);

    final selectedContacts = allContacts
        .where((c) => widget.selectedContactIds.contains(c.contact_id))
        .toList();
    final selectedTags = allTags
        .where((t) => widget.selectedTagIds.contains(t.id))
        .toList();

    return CompositedTransformTarget(
      link: _layerLink,
      child: TapRegion(
        groupId: _tapRegionGroupId,
        onTapOutside: (event) {
          if (_dropdownOverlay != null) {
            _removeDropdown();
            widget.focusNode.unfocus();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected Items Chips
            if (selectedContacts.isNotEmpty || selectedTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    ...selectedTags.map(
                      (tag) => Chip(
                        label: Text(
                          tag.name,
                          style: const TextStyle(color: Color(0xFFFBB03B)),
                        ),
                        backgroundColor: Colors.transparent,
                        deleteIcon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFFFBB03B),
                        ),
                        onDeleted: () => widget.onTagSelected(tag),
                        shape: const StadiumBorder(
                          side: BorderSide(color: Color(0xFFFBB03B)),
                        ),
                      ),
                    ),
                    ...selectedContacts.map(
                      (contact) => Chip(
                        avatar: CircleAvatar(
                          backgroundColor: const Color(0xFFFBB03B),
                          child: Text(
                            contact.name.isNotEmpty
                                ? contact.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        label: Text(contact.name),
                        backgroundColor: Colors.grey.shade200,
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => widget.onContactSelected(contact),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: BorderSide.none,
                      ),
                    ),
                  ],
                ),
              ),

            // Input Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    onTap: _showDropdown,
                    decoration: const InputDecoration(
                      hintText: 'Recipient',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      contentPadding: EdgeInsets.only(bottom: 8),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _toggleDropdown,
                  icon: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
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

class _RecipientList extends ConsumerWidget {
  final String searchText;
  final Set<String> selectedContactIds;
  final Set<String> selectedTagIds;
  final Function(Contact) onContactSelected;
  final Function(Tag) onTagSelected;

  const _RecipientList({
    required this.searchText,
    required this.selectedContactIds,
    required this.selectedTagIds,
    required this.onContactSelected,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);
    final tags = ref.watch(tagsProvider);

    final query = searchText.toLowerCase();

    final filteredContacts = contacts.where((contact) {
      return contact.name.toLowerCase().contains(query) ||
          contact.phone.contains(query);
    }).toList();

    final filteredTags = tags.where((tag) {
      return tag.name.toLowerCase().contains(query);
    }).toList();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            // Tags Section
            if (filteredTags.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.grey.shade100,
                child: const Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...filteredTags.map((tag) => _buildTagItem(tag)),
            ],

            // Contacts Section
            if (filteredContacts.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.grey.shade100,
                child: const Text(
                  'Contacts',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...filteredContacts.map((contact) => _buildContactItem(contact)),
            ],

            // No results
            if (filteredTags.isEmpty && filteredContacts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No results found',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagItem(Tag tag) {
    final isSelected = selectedTagIds.contains(tag.id);

    return InkWell(
      onTap: () => onTagSelected(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFBB03B).withOpacity(0.1) : null,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.label,
              size: 20,
              color: isSelected ? const Color(0xFFFBB03B) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tag.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFFFBB03B) : Colors.black,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFBB03B),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(Contact contact) {
    final isSelected = selectedContactIds.contains(contact.contact_id);

    return InkWell(
      onTap: () => onContactSelected(contact),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFBB03B).withOpacity(0.1) : null,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isSelected
                  ? const Color(0xFFFBB03B)
                  : Colors.grey.shade300,
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFFFBB03B)
                          : Colors.black,
                    ),
                  ),
                  Text(
                    contact.phone,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFBB03B),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
