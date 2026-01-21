import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/tags_provider.dart';
import '../../models/contact.dart';
import '../../models/tag.dart';
import '../modals/tag_contacts_dialog.dart';

class DropdownContacts extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Set<String> selectedContactIds;
  final Set<String> selectedTagIds;
  final Function(Contact) onContactSelected;
  final Function(Tag) onTagSelected;

  final String hintText;
  final bool showContacts;

  const DropdownContacts({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.selectedContactIds,
    required this.selectedTagIds,
    required this.onContactSelected,
    required this.onTagSelected,
    this.hintText = 'Recipient',
    this.showContacts = true,
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
              showContacts: widget.showContacts,
              onContactSelected: (contact) {
                widget.controller.clear();
                widget.onContactSelected(contact);
                _dropdownOverlay?.markNeedsBuild();
              },
              onTagSelected: (tag) {
                widget.controller.clear();
                widget.onTagSelected(tag);
                _dropdownOverlay?.markNeedsBuild();
              },
              onZeroContactsTag: (tag) {
                _removeDropdown();
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => Material(
                      type: MaterialType.transparency,
                      elevation: 24,
                      child: AlertDialog(
                        backgroundColor: Colors.white,
                        title: const Text('No Contacts'),
                        content: Text(
                          'The tag "${tag.name}" has no contacts associated with it.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
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

    // Generate chips list
    final List<Widget> chips = [
      ...selectedTags.map(
        (tag) => GestureDetector(
          onLongPress: () async {
            final allContacts = ref.read(contactsProvider);
            final resultIds = await showDialog<List<String>>(
              context: context,
              builder: (context) =>
                  TagContactsDialog(tag: tag, allContacts: allContacts),
            );

            if (resultIds != null) {
              final contactsInTag = allContacts.where((c) {
                return c.tags.any((t) => t.id == tag.id);
              }).toList();

              final allSelected = resultIds.length == contactsInTag.length;

              if (allSelected) {
                // Keep tag
              } else {
                // Remove tag (explode)
                widget.onTagSelected(tag);

                // Add individual contacts
                for (final contactId in resultIds) {
                  if (!widget.selectedContactIds.contains(contactId)) {
                    final contact = allContacts.firstWhere(
                      (c) => c.contact_id == contactId,
                      orElse: () => Contact(
                        contact_id: '',
                        first_name: '',
                        last_name: '',
                        phone: '',
                        tags: [],
                        created: DateTime.now(),
                      ),
                    );
                    if (contact.contact_id.isNotEmpty) {
                      widget.onContactSelected(contact);
                    }
                  }
                }
              }
            }
          },
          child: Chip(
            label: Text(
              tag.name,
              style: const TextStyle(
                color: Color(0xFFFBB03B),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            backgroundColor: const Color(0xFFFBB03B).withOpacity(0.08),
            deleteIcon: const Icon(
              Icons.cancel,
              size: 16,
              color: Color(0xFFFBB03B),
            ),
            onDeleted: () => widget.onTagSelected(tag),
            shape: StadiumBorder(
              side: BorderSide(color: const Color(0xFFFBB03B).withOpacity(0.3)),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
      if (widget.showContacts)
        ...selectedContacts.map(
          (contact) => Chip(
            avatar: CircleAvatar(
              backgroundColor: const Color(0xFFFBB03B),
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            label: Text(
              contact.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.white,
            deleteIcon: Icon(
              Icons.cancel,
              size: 16,
              color: Colors.grey.shade400,
            ),
            onDeleted: () => widget.onContactSelected(contact),
            shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade200)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          ),
        ),
    ];

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onTap: _showDropdown,
                maxLines: null, // Allow wrapping
                decoration: InputDecoration(
                  prefixIcon: chips.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: chips,
                          ),
                        )
                      : null,
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  hintText: chips.isEmpty ? widget.hintText : null,
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.only(bottom: 8),
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              onPressed: _toggleDropdown,
              icon: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBB03B).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFFFBB03B),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientList extends ConsumerStatefulWidget {
  final String searchText;
  final Set<String> selectedContactIds;
  final Set<String> selectedTagIds;
  final Function(Contact) onContactSelected;
  final Function(Tag) onTagSelected;
  final Function(Tag) onZeroContactsTag;
  final bool showContacts;

  const _RecipientList({
    required this.searchText,
    required this.selectedContactIds,
    required this.selectedTagIds,
    required this.onContactSelected,
    required this.onTagSelected,
    required this.onZeroContactsTag,
    this.showContacts = true,
  });

  @override
  ConsumerState<_RecipientList> createState() => _RecipientListState();
}

class _RecipientListState extends ConsumerState<_RecipientList> {
  bool _isContactsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider);
    final tags = ref.watch(tagsProvider);

    final query = widget.searchText.toLowerCase();

    final filteredContacts = contacts.where((contact) {
      return contact.name.toLowerCase().contains(query) ||
          contact.phone.contains(query);
    }).toList();

    final filteredTags = tags.where((tag) {
      return tag.name.toLowerCase().contains(query);
    }).toList();

    // Determine displayed contacts based on expansion state
    final displayedContacts =
        _isContactsExpanded || filteredContacts.length <= 1
        ? filteredContacts
        : filteredContacts.take(1).toList();

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
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Contacts Section (Moved to Top)
            if (widget.showContacts && filteredContacts.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Contacts',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade400,
                        letterSpacing: 1.1,
                      ),
                    ),
                    if (filteredContacts.length > 1 && !_isContactsExpanded)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isContactsExpanded = true;
                          });
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFBB03B),
                          ),
                        ),
                      ),
                    if (filteredContacts.length > 1 && _isContactsExpanded)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isContactsExpanded = false;
                          });
                        },
                        child: const Text(
                          'See Less',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFBB03B),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ...displayedContacts.map((contact) => _buildContactItem(contact)),
            ],

            // Tags Section (Moved Below Contacts)
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
              ...filteredTags.map((tag) => _buildTagItem(context, tag, ref)),
            ],

            // No results
            if (filteredTags.isEmpty &&
                (widget.showContacts ? filteredContacts.isEmpty : true))
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

  Widget _buildTagItem(BuildContext context, Tag tag, WidgetRef ref) {
    final isSelected = widget.selectedTagIds.contains(tag.id);
    final allContacts = ref.read(contactsProvider);
    final tagContactCount = allContacts
        .where((c) => c.tags.any((t) => t.id == tag.id))
        .length;

    return InkWell(
      onTap: () {
        if (tagContactCount == 0 && !isSelected) {
          widget.onZeroContactsTag(tag);
        } else {
          widget.onTagSelected(tag);
        }
      },
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tag.name,
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
                    '$tagContactCount contacts',
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

  Widget _buildContactItem(Contact contact) {
    final isSelected = widget.selectedContactIds.contains(contact.contact_id);

    return InkWell(
      onTap: () => widget.onContactSelected(contact),
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
