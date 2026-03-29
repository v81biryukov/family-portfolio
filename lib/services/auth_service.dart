import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:universal_platform/universal_platform.dart';

/// Authentication Service - handles PIN and biometric authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  bool _isAuthenticated = false;
  DateTime? _authTime;
  String? _currentUser;

  static const String _pinHashKey = 'auth_pin_hash';
  static const String _biometricEnabledKey = 'auth_biometric_enabled';

  /// Check if user is currently authenticated
  bool get isAuthenticated {
    if (!_isAuthenticated) return false;
    if (_authTime == null) return false;
    
    // Check session expiry
    final sessionDuration = const Duration(minutes: 30);
    final expiryTime = _authTime!.add(sessionDuration);
    
    if (DateTime.now().isAfter(expiryTime)) {
      _isAuthenticated = false;
      return false;
    }
    
    return true;
  }

  /// Get current authenticated user
  String? get currentUser => _currentUser;

  /// Check if biometric authentication is available on this device
  Future<bool> isBiometricAvailable() async {
    if (UniversalPlatform.isWeb) return false;
    
    try {
      final isAvailable = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isAvailable && canCheck;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (UniversalPlatform.isWeb) return [];
    
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if biometric is enrolled (Face ID/Touch ID set up)
  Future<bool> isBiometricEnrolled() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.isNotEmpty;
  }

  /// Check if biometric auth is enabled in app settings
  Future<bool> isBiometricEnabled() async {
    final enabled = await _secureStorage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  /// Authenticate with biometric
  Future<AuthResult> authenticateWithBiometric() async {
    if (UniversalPlatform.isWeb) {
      return const AuthResult(
        success: false,
        message: 'Biometric not available on web',
      );
    }

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your portfolio',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        _setAuthenticated('Biometric User');
        return const AuthResult(success: true, message: 'Authenticated');
      } else {
        return const AuthResult(
          success: false,
          message: 'Authentication cancelled',
        );
      }
    } on PlatformException catch (e) {
      return AuthResult(
        success: false,
        message: 'Biometric error: ${e.message}',
      );
    }
  }

  /// Set up PIN
  Future<bool> setupPIN(String pin) async {
    if (pin.length < 4) return false;
    
    final hash = _hashPIN(pin);
    await _secureStorage.write(key: _pinHashKey, value: hash);
    return true;
  }

  /// Verify PIN
  Future<bool> verifyPIN(String pin) async {
    final storedHash = await _secureStorage.read(key: _pinHashKey);
    if (storedHash == null) return false;
    
    final inputHash = _hashPIN(pin);
    return inputHash == storedHash;
  }

  /// Authenticate with PIN
  Future<AuthResult> authenticateWithPIN(String pin) async {
    final isValid = await verifyPIN(pin);
    
    if (isValid) {
      _setAuthenticated('PIN User');
      return const AuthResult(success: true, message: 'Authenticated');
    } else {
      return const AuthResult(success: false, message: 'Invalid PIN');
    }
  }

  /// Check if PIN is set up
  Future<bool> isPINSet() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    return hash != null;
  }

  /// Hash PIN using SHA-256
  String _hashPIN(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Set authenticated state
  void _setAuthenticated(String user) {
    _isAuthenticated = true;
    _authTime = DateTime.now();
    _currentUser = user;
  }

  /// Logout - clear authentication
  Future<void> logout() async {
    _isAuthenticated = false;
    _authTime = null;
    _currentUser = null;
  }

  /// Clear all auth data (for reset)
  Future<void> clearAllAuth() async {
    await logout();
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _biometricEnabledKey);
  }

  /// Get auth status for UI
  Future<AuthStatus> getAuthStatus() async {
    final pinSet = await isPINSet();
    final biometricAvailable = await isBiometricAvailable();
    final biometricEnabled = await isBiometricEnabled();
    final biometricEnrolled = await isBiometricEnrolled();

    return AuthStatus(
      isAuthenticated: isAuthenticated,
      pinSet: pinSet,
      biometricAvailable: biometricAvailable,
      biometricEnabled: biometricEnabled,
      biometricEnrolled: biometricEnrolled,
    );
  }
}

/// Authentication result
class AuthResult {
  final bool success;
  final String message;

  const AuthResult({
    required this.success,
    required this.message,
  });
}

/// Authentication status for UI
class AuthStatus {
  final bool isAuthenticated;
  final bool pinSet;
  final bool biometricAvailable;
  final bool biometricEnabled;
  final bool biometricEnrolled;

  const AuthStatus({
    required this.isAuthenticated,
    required this.pinSet,
    required this.biometricAvailable,
    required this.biometricEnabled,
    required this.biometricEnrolled,
  });

  bool get needsSetup => !pinSet && !biometricEnabled;
}
