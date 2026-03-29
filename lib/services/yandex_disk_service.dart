import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/constants.dart';

/// Yandex.Disk API Service
/// Handles OAuth authentication and file operations
class YandexDiskService {
  static final YandexDiskService _instance = YandexDiskService._internal();
  factory YandexDiskService() => _instance;
  YandexDiskService._internal();

  final _secureStorage = const FlutterSecureStorage();
  final _dio = Dio();
  final _uuid = const Uuid();
  
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  // OAuth Configuration
  static const String _clientId = AppConstants.yandexClientId;
  static const String _clientSecret = AppConstants.yandexClientSecret;
  static const String _redirectUri = AppConstants.yandexRedirectUri;
  
  static const String _oauthUrl = 'https://oauth.yandex.com/authorize';
  static const String _tokenUrl = 'https://oauth.yandex.com/token';
  static const String _apiBaseUrl = 'https://cloud-api.yandex.net/v1/disk';
  
  static const String _appFolder = '/Apps/FamilyPortfolio';

  /// Check if user is authenticated
  bool get isAuthenticated => _accessToken != null && !isTokenExpired;
  
  /// Check if token is expired
  bool get isTokenExpired {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }

  /// Initialize service and load saved tokens
  Future<void> initialize() async {
    _accessToken = await _secureStorage.read(key: 'yandex_access_token');
    _refreshToken = await _secureStorage.read(key: 'yandex_refresh_token');
    final expiryStr = await _secureStorage.read(key: 'yandex_token_expiry');
    if (expiryStr != null) {
      _tokenExpiry = DateTime.parse(expiryStr);
    }
    
    // Setup Dio with auth header
    _dio.options.headers['Accept'] = 'application/json';
    if (_accessToken != null) {
      _dio.options.headers['Authorization'] = 'OAuth $_accessToken';
    }
  }

  /// Get OAuth authorization URL
  String getAuthorizationUrl() {
    final params = {
      'response_type': 'code',
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'scope': 'cloud_api:disk.write cloud_api:disk.read',
      'state': _uuid.v4(),
    };
    
    final uri = Uri.parse(_oauthUrl).replace(queryParameters: params);
    return uri.toString();
  }

  /// Exchange authorization code for access token
  Future<bool> exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'redirect_uri': _redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresIn: data['expires_in'],
        );
        return true;
      }
      
      debugPrint('Token exchange failed: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error exchanging code: $e');
      return false;
    }
  }

  /// Refresh access token
  Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken,
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresIn: data['expires_in'],
        );
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }

  /// Save tokens securely
  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    
    await _secureStorage.write(key: 'yandex_access_token', value: accessToken);
    await _secureStorage.write(key: 'yandex_refresh_token', value: refreshToken);
    await _secureStorage.write(
      key: 'yandex_token_expiry',
      value: _tokenExpiry!.toIso8601String(),
    );
    
    _dio.options.headers['Authorization'] = 'OAuth $accessToken';
  }

  /// Clear all tokens (logout)
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    
    await _secureStorage.delete(key: 'yandex_access_token');
    await _secureStorage.delete(key: 'yandex_refresh_token');
    await _secureStorage.delete(key: 'yandex_token_expiry');
    
    _dio.options.headers.remove('Authorization');
  }

  /// Ensure app folder exists on Yandex.Disk
  Future<bool> ensureAppFolder() async {
    try {
      final response = await _dio.put(
        '$_apiBaseUrl/resources',
        queryParameters: {
          'path': _appFolder,
        },
      );
      return response.statusCode == 201 || response.statusCode == 409;
    } catch (e) {
      debugPrint('Error creating folder: $e');
      return false;
    }
  }

  /// Upload JSON data to Yandex.Disk
  Future<bool> uploadData(String filename, Map<String, dynamic> jsonData) async {
    try {
      if (isTokenExpired) {
        final refreshed = await refreshToken();
        if (!refreshed) return false;
      }

      await ensureAppFolder();
      
      final filePath = '$_appFolder/$filename';
      final jsonString = jsonEncode(jsonData);
      final bytes = utf8.encode(jsonString);
      
      // Get upload URL
      final uploadUrlResponse = await _dio.get(
        '$_apiBaseUrl/resources/upload',
        queryParameters: {
          'path': filePath,
          'overwrite': 'true',
        },
      );
      
      if (uploadUrlResponse.statusCode != 200) {
        return false;
      }
      
      final uploadUrl = uploadUrlResponse.data['href'];
      
      // Upload file
      final uploadResponse = await _dio.put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Content-Length': bytes.length,
          },
        ),
      );
      
      return uploadResponse.statusCode == 201 || uploadResponse.statusCode == 202;
    } catch (e) {
      debugPrint('Error uploading data: $e');
      return false;
    }
  }

  /// Download JSON data from Yandex.Disk
  Future<Map<String, dynamic>?> downloadData(String filename) async {
    try {
      if (isTokenExpired) {
        final refreshed = await refreshToken();
        if (!refreshed) return null;
      }

      final filePath = '$_appFolder/$filename';
      
      // Get download URL
      final downloadUrlResponse = await _dio.get(
        '$_apiBaseUrl/resources/download',
        queryParameters: {
          'path': filePath,
        },
      );
      
      if (downloadUrlResponse.statusCode != 200) {
        return null;
      }
      
      final downloadUrl = downloadUrlResponse.data['href'];
      
      // Download file
      final downloadResponse = await _dio.get(downloadUrl);
      
      if (downloadResponse.statusCode == 200) {
        return jsonDecode(downloadResponse.data);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error downloading data: $e');
      return null;
    }
  }

  /// List all files in the app folder
  Future<List<Map<String, dynamic>>> listFamilyFiles() async {
    try {
      if (isTokenExpired) {
        final refreshed = await refreshToken();
        if (!refreshed) return [];
      }

      final response = await _dio.get(
        '$_apiBaseUrl/resources',
        queryParameters: {
          'path': _appFolder,
          'limit': 100,
        },
      );
      
      if (response.statusCode == 200) {
        final items = response.data['_embedded']?['items'] as List? ?? [];
        return items.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error listing files: $e');
      return [];
    }
  }

  /// Get file metadata
  Future<Map<String, dynamic>?> getFileInfo(String filename) async {
    try {
      final filePath = '$_appFolder/$filename';
      
      final response = await _dio.get(
        '$_apiBaseUrl/resources',
        queryParameters: {
          'path': filePath,
        },
      );
      
      if (response.statusCode == 200) {
        return response.data;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting file info: $e');
      return null;
    }
  }

  /// Delete a file
  Future<bool> deleteFile(String filename) async {
    try {
      final filePath = '$_appFolder/$filename';
      
      final response = await _dio.delete(
        '$_apiBaseUrl/resources',
        queryParameters: {
          'path': filePath,
          'permanently': 'true',
        },
      );
      
      return response.statusCode == 202 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }
}

// Provider for YandexDiskService
final yandexDiskProvider = Provider<YandexDiskService>((ref) {
  return YandexDiskService();
});
