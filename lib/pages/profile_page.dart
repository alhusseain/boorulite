import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/block_list_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/feed_provider.dart';
import '../models/tag.dart';
import '../services/booru_api.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SafeArea(
      child: Column(
        children: [
          AppBar(
            title: Text(
              'Settings & Content Filtering',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            backgroundColor: colorScheme.surface,
            elevation: 0,
          ),
          const Expanded(child: SettingsContent()),
        ],
      ),
    );
  }
}

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Maturity Rating Section
          _SettingsSection(
            title: 'Maturity Rating',
            icon: Icons.shield,
            children: const [MaturityRatingSettings()],
          ),
          const SizedBox(height: 24.0),
          
          // Dark Mode Section
          _SettingsSection(
            title: 'Appearance',
            icon: Icons.dark_mode,
            children: const [DarkModeSettings()],
          ),
          const SizedBox(height: 24.0),
          
          // Block List Section
          _SettingsSection(
            title: 'Block Tags',
            icon: Icons.block,
            children: const [BlockListManager()],
          ),
        ],
      ),
    );
  }
}

/// Reusable section widget for grouping related settings.
class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: colorScheme.secondary.withAlpha(150),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: colorScheme.secondary, size: 24.0),
                const SizedBox(width: 12.0),
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: colorScheme.secondary.withAlpha(100), height: 1.0),
          ...children,
        ],
      ),
    );
  }
}

/// Maturity rating settings widget.
class MaturityRatingSettings extends StatelessWidget {
  const MaturityRatingSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildRadioTile(
                colorScheme: colorScheme,
                title: 'Safe Only',
                subtitle: 'Show only safe content',
                value: 's',
                groupValue: settings.maturityRating,
                onChanged: (value) async {
                  await settings.setMaturityRating(value!);
                  // Refresh feed to apply rating filter
                  await Provider.of<FeedProvider>(context, listen: false).fetchPosts();
                },
              ),
              _buildRadioTile(
                colorScheme: colorScheme,
                title: 'Safe + Questionable',
                subtitle: 'Include questionable content',
                value: 'q',
                groupValue: settings.maturityRating,
                onChanged: (value) async {
                  await settings.setMaturityRating(value!);
                  // Refresh feed to apply rating filter
                  await Provider.of<FeedProvider>(context, listen: false).fetchPosts();
                },
              ),
              _buildRadioTile(
                colorScheme: colorScheme,
                title: 'All Ratings',
                subtitle: 'Show all content including explicit',
                value: '',
                groupValue: settings.maturityRating,
                onChanged: (value) async {
                  await settings.setMaturityRating(value!);
                  // Refresh feed to apply rating filter
                  await Provider.of<FeedProvider>(context, listen: false).fetchPosts();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadioTile({
    required ColorScheme colorScheme,
    required String title,
    required String subtitle,
    required String value,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(title, style: TextStyle(color: colorScheme.onSurface)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: colorScheme.onSurface.withAlpha(180),
          fontSize: 12.0,
        ),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: colorScheme.primary,
    );
  }
}

/// Dark mode settings widget.
class DarkModeSettings extends StatelessWidget {
  const DarkModeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SwitchListTile(
            title: Text(
              'Dark Mode',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            subtitle: Text(
              'Toggle between dark and light theme',
              style: TextStyle(
                color: colorScheme.onSurface.withAlpha(180),
                fontSize: 12.0,
              ),
            ),
            value: settings.isDarkMode,
            onChanged: (value) {
              settings.setDarkMode(value);
            },
            activeColor: colorScheme.primary,
            activeTrackColor: colorScheme.secondary,
          ),
        );
      },
    );
  }
}

/// Block list management widget.
class BlockListManager extends StatefulWidget {
  const BlockListManager({super.key});

  @override
  State<BlockListManager> createState() => _BlockListManagerState();
}

class _BlockListManagerState extends State<BlockListManager> {
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<Tag> _suggestions = [];
  bool _isLoading = false;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _tagController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tagController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _tagController.text.trim();
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

  Future<void> _addTag() async {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty) {
      final blockListProvider = Provider.of<BlockListProvider>(context, listen: false);
      await blockListProvider.addTag(tag);
      _tagController.clear();
      setState(() => _suggestions = []);
      // Refresh feed to apply block list
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      await feedProvider.fetchPosts();
    }
  }

  Future<void> _onTagSuggestionSelected(String tagName) async {
    _tagController.text = tagName;
    await _addTag();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      focusNode: _focusNode,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Add tag to block list',
                        labelStyle: TextStyle(color: colorScheme.onSurface.withAlpha(180)),
                        hintText: 'Type to search tags...',
                        hintStyle: TextStyle(color: colorScheme.onSurface.withAlpha(120)),
                        prefixIcon: Icon(
                          Icons.search,
                          color: colorScheme.onSurface.withAlpha(150),
                        ),
                        suffixIcon: _isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              )
                            : null,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colorScheme.secondary.withAlpha(150)),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colorScheme.primary),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  IconButton(
                    icon: Icon(Icons.add, color: colorScheme.primary),
                    onPressed: _addTag,
                    tooltip: 'Add tag',
                  ),
                ],
              ),
              // Tag suggestions dropdown
              if (_suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: colorScheme.secondary.withAlpha(150),
                      width: 1.0,
                    ),
                  ),
                  constraints: const BoxConstraints(maxHeight: 200.0),
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
                            fontSize: 12.0,
                          ),
                        ),
                        onTap: () => _onTagSuggestionSelected(tag.name),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12.0),
          Consumer<BlockListProvider>(
            builder: (context, provider, child) {
              if (provider.blockList.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No blocked tags. Add tags above to filter content.',
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha(150),
                      fontSize: 14.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200.0),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.blockList.length,
                  itemBuilder: (context, index) {
                    final tag = provider.blockList[index];
                    return ListTile(
                      title: Text(
                        tag,
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: colorScheme.error),
                        onPressed: () async {
                          final blockListProvider = Provider.of<BlockListProvider>(context, listen: false);
                          await blockListProvider.removeTag(tag);
                          // Refresh feed to apply block list changes
                          final feedProvider = Provider.of<FeedProvider>(context, listen: false);
                          await feedProvider.fetchPosts();
                        },
                        tooltip: 'Remove tag',
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
