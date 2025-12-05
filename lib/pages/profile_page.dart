import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/block_list_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_colors.dart';

/// Profile page that functions as a comprehensive content filtering and settings screen.
/// 
/// This page allows users to:
/// - Manage block list of tags
/// - Configure content quality preferences
/// - Adjust display and refresh settings
/// - Set content filtering options
/// - Configure video playback settings
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          AppBar(
            title: Text(
              'Settings & Content Filtering',
              style: TextStyle(color: AppColors.darkScheme.onSurface),
            ),
            backgroundColor: AppColors.darkScheme.surface,
            elevation: 0,
          ),
          const Expanded(child: SettingsContent()),
        ],
      ),
    );
  }
}

/// Main content widget with all settings sections in a scrollable view.
class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Block List Section
          _SettingsSection(
            title: 'Block List',
            icon: Icons.block,
            children: const [BlockListManager()],
          ),
          const SizedBox(height: 24.0),
          
          // Content Quality Section
          _SettingsSection(
            title: 'Content Quality',
            icon: Icons.high_quality,
            children: const [ContentQualitySettings()],
          ),
          const SizedBox(height: 24.0),
          
          // Display Preferences Section
          _SettingsSection(
            title: 'Display Preferences',
            icon: Icons.display_settings,
            children: const [DisplaySettings()],
          ),
          const SizedBox(height: 24.0),
          
          // Content Filtering Section
          _SettingsSection(
            title: 'Content Filtering',
            icon: Icons.filter_list,
            children: const [ContentFilterSettings()],
          ),
          const SizedBox(height: 24.0),
          
          // Video Settings Section
          _SettingsSection(
            title: 'Video Settings',
            icon: Icons.video_settings,
            children: const [VideoSettings()],
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppColors.periwinkleBlue,
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
                Icon(icon, color: AppColors.brightBlue, size: 24.0),
                const SizedBox(width: 12.0),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.chinoBeige,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.periwinkleBlue, height: 1.0),
          ...children,
        ],
      ),
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

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text;
    if (tag.trim().isNotEmpty) {
      Provider.of<BlockListProvider>(context, listen: false).addTag(tag);
      _tagController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  style: TextStyle(color: AppColors.chinoBeige),
                  decoration: InputDecoration(
                    labelText: 'Add tag to block list',
                    labelStyle: TextStyle(color: AppColors.chinoBeige),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.periwinkleBlue),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.brightBlue),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton(
                icon: Icon(Icons.add, color: AppColors.brightBlue),
                onPressed: _addTag,
                tooltip: 'Add tag',
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
                      color: AppColors.chinoBeige.withValues(alpha: 0.6),
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
                        style: TextStyle(color: AppColors.chinoBeige),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: AppColors.frenchFuchsia),
                        onPressed: () {
                          Provider.of<BlockListProvider>(context, listen: false)
                              .removeTag(tag);
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

/// Content quality settings widget.
class ContentQualitySettings extends StatelessWidget {
  const ContentQualitySettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildRadioTile(
                context: context,
                title: 'High Quality',
                value: 'high_quality',
                groupValue: settings.contentQuality,
                onChanged: (value) {
                  settings.setContentQuality(value!);
                },
              ),
              _buildRadioTile(
                context: context,
                title: 'Medium Quality',
                value: 'medium',
                groupValue: settings.contentQuality,
                onChanged: (value) {
                  settings.setContentQuality(value!);
                },
              ),
              _buildRadioTile(
                context: context,
                title: 'Any Quality',
                value: 'any',
                groupValue: settings.contentQuality,
                onChanged: (value) {
                  settings.setContentQuality(value!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadioTile({
    required BuildContext context,
    required String title,
    required String value,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(title, style: TextStyle(color: AppColors.chinoBeige)),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppColors.brightBlue,
    );
  }
}

/// Display settings widget.
class DisplaySettings extends StatelessWidget {
  const DisplaySettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text(
                  'Auto Refresh',
                  style: TextStyle(color: AppColors.chinoBeige),
                ),
                subtitle: Text(
                  'Automatically refresh content every ${settings.refreshInterval}s',
                  style: TextStyle(
                    color: AppColors.chinoBeige.withValues(alpha: 0.7),
                    fontSize: 12.0,
                  ),
                ),
                value: settings.autoRefresh,
                onChanged: (value) {
                  settings.setAutoRefresh(value);
                },
                activeThumbColor: AppColors.brightBlue,
                activeTrackColor: AppColors.periwinkleBlue,
              ),
              if (settings.autoRefresh) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Text(
                        'Refresh Interval:',
                        style: TextStyle(color: AppColors.chinoBeige),
                      ),
                      Expanded(
                        child: Slider(
                          value: settings.refreshInterval.toDouble(),
                          min: 10,
                          max: 120,
                          divisions: 11,
                          label: '${settings.refreshInterval}s',
                          onChanged: (value) {
                            settings.setRefreshInterval(value.toInt());
                          },
                          activeColor: AppColors.brightBlue,
                        ),
                      ),
                      Text(
                        '${settings.refreshInterval}s',
                        style: TextStyle(color: AppColors.chinoBeige),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(color: AppColors.periwinkleBlue),
              _buildRadioTile(
                context: context,
                title: 'Grid View',
                value: 'grid',
                groupValue: settings.displayMode,
                onChanged: (value) {
                  settings.setDisplayMode(value!);
                },
              ),
              _buildRadioTile(
                context: context,
                title: 'List View',
                value: 'list',
                groupValue: settings.displayMode,
                onChanged: (value) {
                  settings.setDisplayMode(value!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadioTile({
    required BuildContext context,
    required String title,
    required String value,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(title, style: TextStyle(color: AppColors.chinoBeige)),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppColors.brightBlue,
    );
  }
}

/// Content filter settings widget.
class ContentFilterSettings extends StatelessWidget {
  const ContentFilterSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text(
                  'Show Only Sakuga',
                  style: TextStyle(color: AppColors.chinoBeige),
                ),
                subtitle: const Text(
                  'Filter to show only high-quality sakuga animations',
                  style: TextStyle(
                    color: AppColors.chinoBeige,
                    fontSize: 12.0,
                  ),
                ),
                value: settings.showOnlySakuga,
                onChanged: (value) {
                  settings.setShowOnlySakuga(value);
                },
                activeThumbColor: AppColors.brightBlue,
                activeTrackColor: AppColors.periwinkleBlue,
              ),
              const Divider(color: AppColors.periwinkleBlue),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text(
                      'Minimum Rating:',
                      style: TextStyle(color: AppColors.chinoBeige),
                    ),
                    Expanded(
                      child: Slider(
                        value: settings.minRating.toDouble(),
                        min: 0,
                        max: 5,
                        divisions: 5,
                        label: '${settings.minRating}/5',
                        onChanged: (value) {
                          settings.setMinRating(value.toInt());
                        },
                        activeColor: AppColors.brightBlue,
                      ),
                    ),
                    Text(
                      '${settings.minRating}/5',
                      style: TextStyle(color: AppColors.chinoBeige),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Video settings widget.
class VideoSettings extends StatelessWidget {
  const VideoSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text(
                  'Auto Play Videos',
                  style: TextStyle(color: AppColors.chinoBeige),
                ),
                subtitle: const Text(
                  'Automatically play videos when opened',
                  style: TextStyle(
                    color: AppColors.chinoBeige,
                    fontSize: 12.0,
                  ),
                ),
                value: settings.autoPlay,
                onChanged: (value) {
                  settings.setAutoPlay(value);
                },
                activeThumbColor: AppColors.brightBlue,
                activeTrackColor: AppColors.periwinkleBlue,
              ),
              const Divider(color: AppColors.periwinkleBlue),
              _buildRadioTile(
                context: context,
                title: 'Original Quality',
                value: 'original',
                groupValue: settings.videoQuality,
                onChanged: (value) {
                  settings.setVideoQuality(value!);
                },
              ),
              _buildRadioTile(
                context: context,
                title: 'High Quality',
                value: 'high',
                groupValue: settings.videoQuality,
                onChanged: (value) {
                  settings.setVideoQuality(value!);
                },
              ),
              _buildRadioTile(
                context: context,
                title: 'Medium Quality',
                value: 'medium',
                groupValue: settings.videoQuality,
                onChanged: (value) {
                  settings.setVideoQuality(value!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadioTile({
    required BuildContext context,
    required String title,
    required String value,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(title, style: TextStyle(color: AppColors.chinoBeige)),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppColors.brightBlue,
    );
  }
}
