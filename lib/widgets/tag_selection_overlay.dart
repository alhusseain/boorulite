import 'package:flutter/material.dart';

class TagSelectionOverlay extends StatefulWidget {
  final List<String> tags;
  final VoidCallback onClose;
  final Function(List<String>) onConfirm;

  const TagSelectionOverlay({
    super.key,
    required this.tags,
    required this.onClose,
    required this.onConfirm,
  });

  @override
  State<TagSelectionOverlay> createState() => _TagSelectionOverlayState();
}

class _TagSelectionOverlayState extends State<TagSelectionOverlay> {
  final Set<String> _selectedTags = {};

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _onConfirmPressed() {
    widget.onConfirm(_selectedTags.toList());
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withAlpha(180),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent tap from closing when tapping the card
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select tags to block',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (widget.tags.isEmpty)
                    Text(
                      'No tags available',
                      style: TextStyle(color: colorScheme.onSurface.withAlpha(150)),
                      textAlign: TextAlign.center,
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: widget.tags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return GestureDetector(
                          onTap: () => _toggleTag(tag),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? colorScheme.primary : colorScheme.outline.withAlpha(100),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: widget.onClose,
                          child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedTags.isEmpty ? null : _onConfirmPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          child: const Text('Block'),
                        ),
                      ),
                    ],
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
