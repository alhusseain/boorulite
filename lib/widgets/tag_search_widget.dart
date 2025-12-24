import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../services/booru_api.dart';

class TagSearchWidget extends StatefulWidget {
  final VoidCallback onClose;
  final Function(List<String>) onSearch;
  final List<String> initialTags;

  const TagSearchWidget({ super.key, required this.onClose, required this.onSearch, this.initialTags = const [], });

  @override
  State<TagSearchWidget> createState() => _TagSearchWidgetState();
}

class _TagSearchWidgetState extends State<TagSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<Tag> _suggestions = [];
  bool _isLoading = false;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
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
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _isLoading = true);
    try {
      final tags = await _api.fetchTags(namePattern: query);
      if (!mounted) return;
      setState(() {
        _suggestions = tags;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
    }
  }

  void _onTagSelected(String name) {
    widget.onSearch([name]);
  }

  void _onSubmit(String query) {
    if (query.trim().isEmpty) return;
    final tags = query.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tags.isNotEmpty) {
      widget.onSearch(tags);
    }
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
                                onSubmitted: _onSubmit,
                                style: TextStyle(color: colorScheme.onSurface),
                                decoration: InputDecoration(
                                  hintText: 'Search tags...',
                                  hintStyle: TextStyle(color: colorScheme.onSurface.withAlpha(100)),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: colorScheme.onSurface.withAlpha(150),
                                  ),
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
                        if (_controller.text.length < 2 && _suggestions.isEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.lightbulb_outline, size: 14, color: colorScheme.onSurface.withAlpha(100)),
                                const SizedBox(width: 6),
                                Text(
                                  'Type to search for tags',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurface.withAlpha(100),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_suggestions.isNotEmpty) ...[
                          Divider(height: 1, color: colorScheme.outline.withAlpha(50)),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 300),
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
                                  onTap: () => _onTagSelected(tag.name),
                                );
                              },
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
