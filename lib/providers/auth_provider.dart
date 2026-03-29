import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

/// Auth state
@immutable
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final bool pinSet;
  final bool biometricAvailable;
  final bool biometricEnabled;
  final bool biometricEnrolled;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.pinSet = false,
    this.biometricAvailable = false,
    this.biometricEnabled = false,
    this.biometricEnrolled = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool? pinSet,
    bool? biometricAvailable,
    bool? biometricEnabled,
    bool? biometricEnrolled,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pinSet: pinSet ?? this.pinSet,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      biometricEnrolled: biometricEnrolled ?? this.biometricEnrolled,
    );
  }
}

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    
    final status = await _authService.getAuthStatus();
    
    state = state.copyWith(
      isAuthenticated: status.isAuthenticated,
      isLoading: false,
      pinSet: status.pinSet,
      biometricAvailable: status.biometricAvailable,
      biometricEnabled: status.biometricEnabled,
      biometricEnrolled: status.biometricEnrolled,
    );
  }

  Future<void> refreshStatus() async {
    final status = await _authService.getAuthStatus();
    
    state = state.copyWith(
      isAuthenticated: status.isAuthenticated,
      pinSet: status.pinSet,
      biometricAvailable: status.biometricAvailable,
      biometricEnabled: status.biometricEnabled,
      biometricEnrolled: status.biometricEnrolled,
    );
  }

  Future<bool> authenticateWithBiometric() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _authService.authenticateWithBiometric();
    
    if (result.success) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.message,
      );
      return false;
    }
  }

  Future<bool> authenticateWithPIN(String pin) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _authService.authenticateWithPIN(pin);
    
    if (result.success) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.message,
      );
      return false;
    }
  }

  Future<bool> setupPIN(String pin) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final success = await _authService.setupPIN(pin);
    
    if (success) {
      await _authService.authenticateWithPIN(pin);
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        pinSet: true,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set up PIN',
      );
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _authService.setBiometricEnabled(enabled);
    state = state.copyWith(biometricEnabled: enabled);
  }

  Future<void> logout() async {
    await _authService.logout();
    state = state.copyWith(isAuthenticated: false);
  }

  Future<void> clearError() async {
    state = state.copyWith(error: null);
  }
}

/// Provider for auth service
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for auth notifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
