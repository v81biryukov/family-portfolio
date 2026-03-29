import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync_service.dart';
import '../services/yandex_disk_service.dart';
import '../models/asset_model.dart';
import '../models/exchange_rate_model.dart';
import '../models/settings_model.dart';

/// Sync state
@immutable
class SyncState {
  final bool isSyncing;
  final bool isOnline;
  final bool isAuthenticated;
  final String? lastSyncTime;
  final String? error;
  final List<Asset> assets;
  final List<ExchangeRate> exchangeRates;
  final AppSettings? settings;

  const SyncState({
    this.isSyncing = false,
    this.isOnline = true,
    this.isAuthenticated = false,
    this.lastSyncTime,
    this.error,
    this.assets = const [],
    this.exchangeRates = const [],
    this.settings,
  });

  SyncState copyWith({
    bool? isSyncing,
    bool? isOnline,
    bool? isAuthenticated,
    String? lastSyncTime,
    String? error,
    List<Asset>? assets,
    List<ExchangeRate>? exchangeRates,
    AppSettings? settings,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      isOnline: isOnline ?? this.isOnline,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      error: error,
      assets: assets ?? this.assets,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      settings: settings ?? this.settings,
    );
  }
}

/// Sync notifier
class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;
  final YandexDiskService _yandexDisk;

  SyncNotifier(this._syncService, this._yandexDisk) : super(const SyncState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _syncService.initialize();
    await _yandexDisk.initialize();
    
    _refreshData();
  }

  void _refreshData() {
    final lastSync = _syncService.lastSync;
    
    state = state.copyWith(
      isAuthenticated: _yandexDisk.isAuthenticated,
      lastSyncTime: lastSync?.toIso8601String(),
      assets: _syncService.assets,
      exchangeRates: _syncService.exchangeRates,
      settings: _syncService.settings,
    );
  }

  Future<void> sync() async {
    state = state.copyWith(isSyncing: true, error: null);
    
    final result = await _syncService.syncAll();
    
    if (result.success) {
      _refreshData();
      state = state.copyWith(isSyncing: false);
    } else {
      state = state.copyWith(
        isSyncing: false,
        error: result.message,
      );
    }
  }

  Future<void> forceUpload() async {
    state = state.copyWith(isSyncing: true, error: null);
    
    final success = await _syncService.forceUpload();
    
    if (success) {
      _refreshData();
      state = state.copyWith(isSyncing: false);
    } else {
      state = state.copyWith(
        isSyncing: false,
        error: 'Failed to upload data',
      );
    }
  }

  Future<void> forceDownload() async {
    state = state.copyWith(isSyncing: true, error: null);
    
    final success = await _syncService.forceDownload();
    
    if (success) {
      _refreshData();
      state = state.copyWith(isSyncing: false);
    } else {
      state = state.copyWith(
        isSyncing: false,
        error: 'Failed to download data',
      );
    }
  }

  Future<void> addAsset(Asset asset) async {
    await _syncService.addAsset(asset);
    _refreshData();
  }

  Future<void> updateAsset(Asset asset) async {
    await _syncService.updateAsset(asset);
    _refreshData();
  }

  Future<void> deleteAsset(String id) async {
    await _syncService.deleteAsset(id);
    _refreshData();
  }

  Future<void> updateExchangeRate(ExchangeRate rate) async {
    await _syncService.updateExchangeRate(rate);
    _refreshData();
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _syncService.updateSettings(settings);
    _refreshData();
  }

  Future<void> checkOnlineStatus() async {
    final isOnline = await _syncService.isOnline();
    state = state.copyWith(isOnline: isOnline);
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(
      isAuthenticated: _yandexDisk.isAuthenticated,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> clearAllData() async {
    // Clear all assets
    for (final asset in state.assets) {
      await _syncService.deleteAsset(asset.id);
    }
    _refreshData();
  }
}

/// Provider for sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

/// Provider for sync notifier
final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final yandexDisk = ref.watch(yandexDiskProvider);
  return SyncNotifier(syncService, yandexDisk);
});
