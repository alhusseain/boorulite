import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;

/// Model class representing a tag from the Sakugabooru API.
class SakugaTag {
  final String name;
  final int count;
  final int type;

  SakugaTag({
    required this.name,
    required this.count,
    required this.type,
  });

  /// Factory constructor to create a SakugaTag from JSON.
  factory SakugaTag.fromJson(Map<String, dynamic> json) {
    return SakugaTag(
      name: json['name'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      type: json['type'] as int? ?? 0,
    );
  }

  @override
  String toString() => name;
}

/// Service class for interacting with the Sakugabooru API.
/// Handles tag searching with debouncing to prevent API spam.
/// 
/// For web platform, uses a CORS proxy to bypass browser CORS restrictions.
class SakugaApiService {
  static const String _baseUrl = 'https://www.sakugabooru.com';
  static const String _tagEndpoint = '/tag.json';
  static const int _debounceMs = 500;
  static const int _searchLimit = 10;
  
  // CORS proxy for web platform (since Sakugabooru API doesn't support CORS)
  // Using allorigins.win as a free CORS proxy service
  // Format: https://api.allorigins.win/raw?url=ENCODED_URL
  static const String _corsProxy = 'https://api.allorigins.win/raw?url=';

  Timer? _debounceTimer;

  /// Searches for tags matching the query string.
  /// 
  /// Uses wildcard matching: `*query*` to find partial matches.
  /// Implements debouncing (500ms) to prevent excessive API calls while typing.
  /// 
  /// [query] - The search query string.
  /// 
  /// Returns a list of [SakugaTag] objects, or an empty list on error.
  Future<List<SakugaTag>> searchTags(String query) async {
    // Cancel any pending debounce timer
    _debounceTimer?.cancel();

    // If query is empty, return empty list immediately
    if (query.trim().isEmpty) {
      return [];
    }

    // Create a completer to handle the debounced async operation
    final completer = Completer<List<SakugaTag>>();

    _debounceTimer = Timer(Duration(milliseconds: _debounceMs), () async {
      try {
        final results = await _performSearch(query.trim());
        if (!completer.isCompleted) {
          completer.complete(results);
        }
      } catch (e) {
        if (!completer.isCompleted) {
          completer.complete([]);
        }
      }
    });

    return completer.future;
  }

  /// Performs the actual API call to search for tags.
  /// 
  /// Uses the `name` parameter with `*` wildcards for pattern matching.
  /// 
  /// [query] - The search query (already trimmed).
  /// 
  /// Returns a list of [SakugaTag] objects.
  /// Returns an empty list on any error (network, parsing, etc.).
  Future<List<SakugaTag>> _performSearch(String query) async {
    try {
      // Use name parameter with * wildcards (works with Sakugabooru API)
      // Format 1: *query* (substring match - finds tags containing the query)
      final encodedQuery1 = Uri.encodeComponent('*$query*');
      // Format 2: query* (prefix match - fallback if substring yields no results)
      final encodedQuery2 = Uri.encodeComponent('$query*');
      
      // Construct the API URL with name parameter
      final apiUrl = '$_baseUrl$_tagEndpoint?name=$encodedQuery1&limit=$_searchLimit&order=count';
      
      // For web platform, use CORS proxy; for mobile/desktop, use direct URL
      // Always use proxy for web to avoid CORS issues
      Uri url;
      final isWeb = kIsWeb;
      
      if (isWeb) {
        // Use CORS proxy for web - encode the full API URL
        final encodedApiUrl = Uri.encodeComponent(apiUrl);
        final proxyUrl = '$_corsProxy$encodedApiUrl';
        url = Uri.parse(proxyUrl);
        debugPrint('=== WEB PLATFORM DETECTED ===');
        debugPrint('Original API URL: $apiUrl');
        debugPrint('Encoded API URL: $encodedApiUrl');
        debugPrint('Proxy URL: $proxyUrl');
        debugPrint('Final URL object: $url');
      } else {
        // Direct API call for mobile/desktop
        url = Uri.parse(apiUrl);
        debugPrint('=== MOBILE/DESKTOP PLATFORM ===');
        debugPrint('Direct API URL: $url');
      }

      // Debug: Print URL for troubleshooting
      debugPrint('Sakuga API Search URL: $url');
      debugPrint('Platform: ${kIsWeb ? "Web (using CORS proxy)" : "Mobile/Desktop (direct)"}');

      // Make HTTP GET request
      // Note: CORS proxy handles headers, so we don't need to set them for web
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );

      // Debug: Print response status
      debugPrint('Sakuga API Response Status: ${response.statusCode}');
      debugPrint('Sakuga API Response Headers: ${response.headers}');

      // Check if request was successful
      if (response.statusCode == 200) {
        // Parse JSON response
        final responseBody = response.body;
        debugPrint('Sakuga API Response Body Length: ${responseBody.length}');
        
        if (responseBody.isEmpty || responseBody.trim() == '[]' || responseBody.trim().isEmpty) {
          debugPrint('Sakuga API: Empty response body, trying prefix match');
          // Try alternative format (prefix match: query*)
          return await _tryAlternativeSearch(query, encodedQuery2);
        }

        try {
          // First check if response is an error object
          final decoded = json.decode(responseBody);
          if (decoded is Map && decoded.containsKey('status') && decoded.containsKey('error')) {
            debugPrint('Sakuga API Error Response: $decoded');
            // This is an error response, try alternative search
            return await _tryAlternativeSearch(query, encodedQuery2);
          }
          
          // If not an error, it should be a list
          if (decoded is! List) {
            debugPrint('Sakuga API: Unexpected response format (not a list): $decoded');
            return await _tryAlternativeSearch(query, encodedQuery2);
          }
          
          final List<dynamic> jsonList = decoded;
          debugPrint('Sakuga API: Found ${jsonList.length} tags');
          
          if (jsonList.isEmpty) {
            // Try alternative format if no results (prefix match)
            return await _tryAlternativeSearch(query, encodedQuery2);
          }
          
          // Convert JSON list to SakugaTag list
          final tags = jsonList
              .map((json) {
                try {
                  return SakugaTag.fromJson(json as Map<String, dynamic>);
                } catch (e) {
                  debugPrint('Error parsing tag: $e, JSON: $json');
                  return null;
                }
              })
              .whereType<SakugaTag>()
              .toList();
          
          return tags;
        } catch (e) {
          debugPrint('Sakuga API JSON Parse Error: $e');
          debugPrint('Response body: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}');
          return [];
        }
      } else {
        // Non-200 status code - log and return empty list
        debugPrint('Sakuga API Error: Status ${response.statusCode}');
        debugPrint('Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        return [];
      }
    } catch (e, stackTrace) {
      // Catch all errors (network, parsing, timeout, CORS, etc.)
      // Log error for debugging
      debugPrint('Sakuga API Exception: $e');
      debugPrint('Exception type: ${e.runtimeType}');
      if (e.toString().contains('CORS') || e.toString().contains('XMLHttpRequest')) {
        debugPrint('CORS Error detected - API may not allow web requests');
      }
      debugPrint('Stack trace: $stackTrace');
      // Return empty list instead of crashing
      return [];
    }
  }

  /// Tries an alternative search format (prefix match: query*).
  Future<List<SakugaTag>> _tryAlternativeSearch(String query, String encodedQuery) async {
    try {
      // Use name parameter with prefix match pattern (already encoded)
      final apiUrl = '$_baseUrl$_tagEndpoint?name=$encodedQuery&limit=$_searchLimit&order=count';
      
      Uri url;
      if (kIsWeb) {
        final encodedApiUrl = Uri.encodeComponent(apiUrl);
        url = Uri.parse('$_corsProxy$encodedApiUrl');
      } else {
        url = Uri.parse(apiUrl);
      }
      
      debugPrint('Trying alternative search URL: $url');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.body.isNotEmpty && response.body.trim() != '[]') {
        // Check if response is an error object
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded.containsKey('status') && decoded.containsKey('error')) {
          debugPrint('Alternative search also returned error: $decoded');
          return [];
        }
        
        if (decoded is! List) {
          debugPrint('Alternative search: Unexpected response format (not a list)');
          return [];
        }
        
        final List<dynamic> jsonList = decoded;
        return jsonList
            .map((json) {
              try {
                return SakugaTag.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                debugPrint('Error parsing tag in alternative search: $e');
                return null;
              }
            })
            .whereType<SakugaTag>()
            .toList();
      }
    } catch (e) {
      debugPrint('Alternative search also failed: $e');
    }
    return [];
  }

  /// Cancels any pending debounce timer.
  /// Call this when the service is being disposed or reset.
  void cancelPendingSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}

