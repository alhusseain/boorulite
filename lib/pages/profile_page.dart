import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../providers/block_list_provider.dart';
import '../providers/settings_provider.dart';
import '../app_colors.dart';
import '../services/sakuga_api_service.dart';
import '../services/preferences_service.dart';

/// Profile page that functions as a comprehensive content filtering and settings screen.
/// 
/// This page allows users to:
/// - Manage block list of tags
/// - Configure content quality preferences
/// - Adjust display and refresh settings
/// - Set content filtering options
/// - Configure video playback settings
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkScheme.surface,
      appBar: AppBar(
        title: Text(
          'Settings & Content Filtering',
          style: TextStyle(color: AppColors.darkScheme.onSurface),
        ),
        backgroundColor: AppColors.darkScheme.surface,
        elevation: 0,
      ),
      body: const SettingsContent(),
    );
  }
}

/// Main content widget with all settings sections in a scrollable view.
class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  String? _profileImagePath;
  final PreferencesService _preferencesService = PreferencesService();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  /// Loads the profile image path from SharedPreferences.
  Future<void> _loadProfileImage() async {
    final path = await _preferencesService.getProfileImagePath();
    if (mounted) {
      setState(() {
        _profileImagePath = path.isEmpty ? null : path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture Section
          Center(
            child: _ProfileAvatar(
              imagePath: _profileImagePath,
              onImageChanged: () => _loadProfileImage(),
            ),
          ),
          const SizedBox(height: 24.0),
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

/// Profile avatar widget with camera/gallery picker functionality.
class _ProfileAvatar extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onImageChanged;

  const _ProfileAvatar({
    required this.imagePath,
    required this.onImageChanged,
  });

  /// Shows a modal bottom sheet with options to take a photo or choose from gallery.
  void _showImagePickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => _ImagePickerOptions(
        onImageChanged: onImageChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImagePickerModal(context),
      child: Stack(
        children: [
          Container(
            width: 120.0,
            height: 120.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.frenchFuchsia,
                width: 3.0,
              ),
              color: AppColors.darkScheme.surface,
            ),
            child: ClipOval(
              child: _buildProfileImage(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 36.0,
              height: 36.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.frenchFuchsia,
                border: Border.all(
                  color: AppColors.darkScheme.surface,
                  width: 3.0,
                ),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the profile image widget, handling both web (base64) and mobile (file path).
  Widget _buildProfileImage() {
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildDefaultAvatar();
    }

    // Check if it's a base64 data URL (web) or file path (mobile)
    if (imagePath!.startsWith('data:image/')) {
      // Web: Use Image.memory with base64 data URL
      try {
        final String base64String = imagePath!.split(',')[1];
        final Uint8List imageBytes = base64Decode(base64String);
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        );
      } catch (e) {
        return _buildDefaultAvatar();
      }
    } else {
      // Mobile/Desktop: Use Image.file
      if (kIsWeb) {
        // On web, if it's not a data URL, show default
        return _buildDefaultAvatar();
      }
      try {
        final file = File(imagePath!);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar();
            },
          );
        } else {
          return _buildDefaultAvatar();
        }
      } catch (e) {
        return _buildDefaultAvatar();
      }
    }
  }

  /// Builds the default avatar when no image is set.
  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.darkScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person,
        size: 60.0,
        color: AppColors.chinoBeige.withValues(alpha: 0.5),
      ),
    );
  }
}

/// Modal bottom sheet widget for image picker options.
class _ImagePickerOptions extends StatelessWidget {
  final VoidCallback onImageChanged;
  final ImagePicker _picker = ImagePicker();
  final PreferencesService _preferencesService = PreferencesService();

  _ImagePickerOptions({required this.onImageChanged});

  /// Handles image picking from camera or gallery.
  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image == null) {
        // User cancelled the picker
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      if (kIsWeb) {
        // For web platform: Convert image to base64 data URL
        final Uint8List imageBytes = await image.readAsBytes();
        final String base64Image = base64Encode(imageBytes);
        final String extension = path.extension(image.name).replaceAll('.', '');
        final String mimeType = extension == 'png' ? 'png' : 'jpeg';
        final String dataUrl = 'data:image/$mimeType;base64,$base64Image';
        
        // Save the data URL to SharedPreferences
        await _preferencesService.saveProfileImagePath(dataUrl);
      } else {
        // For mobile/desktop: Save to file system
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = path.basename(image.path);
        final String savedPath = path.join(appDir.path, 'profile_image_$fileName');

        // Copy the image to the app's documents directory
        final File savedFile = await File(image.path).copy(savedPath);

        // Save the path to SharedPreferences
        await _preferencesService.saveProfileImagePath(savedFile.path);
      }

      // Notify the parent widget to reload the image
      onImageChanged();

      // Close the modal
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile picture updated successfully'),
            backgroundColor: AppColors.brightBlue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Handle any errors (permissions, etc.)
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.frenchFuchsia,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(bottom: 20.0),
            width: 40.0,
            height: 4.0,
            decoration: BoxDecoration(
              color: AppColors.chinoBeige.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Text(
              'Change Profile Picture',
              style: TextStyle(
                color: AppColors.chinoBeige,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Take Photo option (only show on mobile/desktop, not web)
          if (!kIsWeb)
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: AppColors.brightBlue,
              ),
              title: Text(
                'Take Photo',
                style: TextStyle(color: AppColors.chinoBeige),
              ),
              onTap: () => _pickImage(context, ImageSource.camera),
            ),
          // Choose from Gallery option
          ListTile(
            leading: Icon(
              Icons.photo_library,
              color: AppColors.brightBlue,
            ),
            title: Text(
              kIsWeb ? 'Choose Image' : 'Choose from Gallery',
              style: TextStyle(color: AppColors.chinoBeige),
            ),
            onTap: () => _pickImage(context, ImageSource.gallery),
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }
}

/// Block list management widget.
class BlockListManager extends StatelessWidget {
  const BlockListManager({super.key});

  /// Opens a modal bottom sheet for searching and adding tags.
  void _showAddFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => const _TagSearchModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Filter Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddFilterModal(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Filter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.frenchFuchsia,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          // Blocked Tags Display
          Consumer<BlockListProvider>(
            builder: (context, provider, child) {
              if (provider.blockList.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No tags blocked yet. Tap "Add Filter" to search and block tags.',
                    style: TextStyle(
                      color: AppColors.chinoBeige.withValues(alpha: 0.6),
                      fontSize: 14.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: provider.blockList.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: AppColors.frenchFuchsia,
                    deleteIcon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18.0,
                    ),
                    onDeleted: () {
                      Provider.of<BlockListProvider>(context, listen: false)
                          .removeTag(tag);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Modal bottom sheet for searching and selecting tags from Sakugabooru API.
class _TagSearchModal extends StatefulWidget {
  const _TagSearchModal();

  @override
  State<_TagSearchModal> createState() => _TagSearchModalState();
}

class _TagSearchModalState extends State<_TagSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  final SakugaApiService _apiService = SakugaApiService();
  List<SakugaTag> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _apiService.cancelPendingSearch();
    super.dispose();
  }

  /// Handles search text changes with debouncing via the API service.
  void _onSearchChanged() {
    final query = _searchController.text;
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    _apiService.searchTags(query).then((results) {
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          if (results.isEmpty && query.trim().isNotEmpty) {
            _errorMessage = 'No tags found.';
          }
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Search failed: ${error.toString()}';
        });
      }
    });
  }

  /// Handles tag selection - adds to block list and closes modal.
  void _onTagSelected(String tagName, BuildContext context) {
    Provider.of<BlockListProvider>(context, listen: false).addTag(tagName);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
              width: 40.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: AppColors.chinoBeige.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Search Tags to Block',
                style: TextStyle(
                  color: AppColors.chinoBeige,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: AppColors.periwinkleBlue),
            // Search TextField
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: AppColors.chinoBeige),
                decoration: InputDecoration(
                  hintText: 'Type to search tags...',
                  hintStyle: TextStyle(
                    color: AppColors.chinoBeige.withValues(alpha: 0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.chinoBeige,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: AppColors.chinoBeige,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.darkScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: AppColors.periwinkleBlue),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: AppColors.periwinkleBlue),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: AppColors.brightBlue,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            // Search Results List
            Expanded(
              child: _buildResultsList(scrollController),
            ),
          ],
        );
      },
    );
  }

  /// Builds the search results list view.
  Widget _buildResultsList(ScrollController scrollController) {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.brightBlue,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Searching...',
              style: TextStyle(
                color: AppColors.chinoBeige.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Text(
          'Start typing to search for tags',
          style: TextStyle(
            color: AppColors.chinoBeige.withValues(alpha: 0.6),
            fontSize: 14.0,
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: AppColors.frenchFuchsia,
                    fontSize: 14.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Text(
                'No tags found. Try a different search term.',
                style: TextStyle(
                  color: AppColors.chinoBeige.withValues(alpha: 0.6),
                  fontSize: 14.0,
                ),
              ),
            const SizedBox(height: 8.0),
            Text(
              'Tags not found',
              style: TextStyle(
                color: AppColors.chinoBeige.withValues(alpha: 0.4),
                fontSize: 12.0,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final tag = _searchResults[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 4.0,
          ),
          title: Text(
            tag.name,
            style: TextStyle(
              color: AppColors.chinoBeige,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Count: ${tag.count}',
            style: TextStyle(
              color: AppColors.chinoBeige.withValues(alpha: 0.6),
              fontSize: 12.0,
            ),
          ),
          trailing: Icon(
            Icons.add_circle_outline,
            color: AppColors.brightBlue,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(
              color: AppColors.periwinkleBlue.withValues(alpha: 0.3),
            ),
          ),
          onTap: () => _onTagSelected(tag.name, context),
        );
      },
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
