import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../services/booru_api.dart';

class TagSearchWidget extends StatefulWidget {
  final VoidCallback onClose;
  final Function(List<String>) onSearch;
  final List<String> initialTags;

  const TagSearchWidget({
    super.key,
    required this.onClose,
    required this.onSearch,
    this.initialTags = const [],
  });

  @override
  State<TagSearchWidget> createState() => _TagSearchWidgetState();
}

class _TagSearchWidgetState extends State<TagSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<Tag> _suggestions = [];
  List<String> _selectedTags = [];
  bool _isLoading = false;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.initialTags);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _isLoading = true);
    try {
      final tags = await _api.fetchTags(namePattern: query);
      setState(() {
        _suggestions = tags.where((t) => !_selectedTags.contains(t.name)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
    }
  }

  void _addTag(String tagName) {
    setState(() {
      _selectedTags.add(tagName);
      _suggestions = [];
      _controller.clear();
    });
    _onSubmit();
  }

  void _removeTag(String tagName) {
    setState(() {
      _selectedTags.remove(tagName);
    });
  }

  void _onSubmit() {
    widget.onSearch(_selectedTags);
  }

  void _onClear() {
    widget.onSearch([]);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withAlpha(180),
        child: SafeArea(
          child: GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                onChanged: _onSearchChanged,
                                onSubmitted: (_) => _onSubmit(),
                                style: TextStyle(color: colorScheme.onSurface),
                                decoration: InputDecoration(
                                  hintText: 'Search tags...',
                                  hintStyle: TextStyle(color: colorScheme.onSurface.withAlpha(100)),
                                  prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withAlpha(150)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                            if (_isLoading)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            IconButton(
                              onPressed: _onClear,
                              icon: Icon(Icons.close, color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                        if (_selectedTags.isNotEmpty) ...[
                          Divider(height: 1, color: colorScheme.outline.withAlpha(50)),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedTags.map((tag) {
                                return Chip(
                                  label: Text(tag),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () => _removeTag(tag),
                                  backgroundColor: colorScheme.primary.withAlpha(30),
                                  labelStyle: TextStyle(color: colorScheme.primary),
                                  deleteIconColor: colorScheme.primary,
                                  side: BorderSide(color: colorScheme.primary.withAlpha(100)),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        if (_suggestions.isNotEmpty) ...[
                          Divider(height: 1, color: colorScheme.outline.withAlpha(50)),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _suggestions.length,
                              itemBuilder: (context, index) {
                                final tag = _suggestions[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    tag.name,
                                    style: TextStyle(color: colorScheme.onSurface),
                                  ),
                                  trailing: Text(
                                    '${tag.count}',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withAlpha(100),
                                      fontSize: 12,
                                    ),
                                  ),
                                  onTap: () => _addTag(tag.name),
                                );
                              },
                            ),
                          ),
                        ],
                        if (_selectedTags.isNotEmpty) ...[
                          Divider(height: 1, color: colorScheme.outline.withAlpha(50)),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _onSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                ),
                                child: const Text('Search'),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
