import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/asset_model.dart';
import '../models/exchange_rate_model.dart';
import '../models/settings_model.dart';
import 'yandex_disk_service.dart';

/// Sync Service - handles bidirectional sync with Yandex.Disk
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _yandexDisk = YandexDiskService();
  final _uuid = const Uuid();
  final _connectivity = Connectivity();
  
  Box<Asset>? _assetsBox;
  Box<ExchangeRate>? _ratesBox;
  Box<AppSettings>? _settingsBox;
  Box<SyncMetadata>? _syncBox;

  bool _initialized = false;

  /// Initialize Hive boxes
  Future<void> initialize() async {
    if (_initialized) return;

    // Register adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AssetAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ExchangeRateAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncMetadataAdapter());
    }

    // Open boxes
    _assetsBox = await Hive.openBox<Asset>('assets');
    _ratesBox = await Hive.openBox<ExchangeRate>('exchange_rates');
    _settingsBox = await Hive.openBox<AppSettings>('settings');
    _syncBox = await Hive.openBox<SyncMetadata>('sync_metadata');

    // Initialize Yandex.Disk
    await _yandexDisk.initialize();

    _initialized = true;
  }

  /// Check if online
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Full sync - bidirectional with conflict resolution
  Future<SyncResult> syncAll() async {
    if (!await isOnline()) {
      return const SyncResult(
        success: false,
        message: 'No internet connection',
        assetsSynced: 0,
      );
    }

    if (!_yandexDisk.isAuthenticated) {
      return const SyncResult(
        success: false,
        message: 'Not authenticated with Yandex.Disk',
        assetsSynced: 0,
      );
    }

    try {
      int assetsSynced = 0;
      int conflictsResolved = 0;

      // Sync assets
      final assetResult = await _syncAssets();
      assetsSynced = assetResult.synced;
      conflictsResolved += assetResult.conflicts;

      // Sync exchange rates
      await _syncExchangeRates();

      // Sync settings
      await _syncSettings();

      // Update last sync time
      await _updateLastSyncTime();

      return SyncResult(
        success: true,
        message: 'Sync completed successfully',
        assetsSynced: assetsSynced,
        conflictsResolved: conflictsResolved,
      );
    } catch (e) {
      debugPrint('Sync error: $e');
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        assetsSynced: 0,
      );
    }
  }

  /// Sync assets with conflict resolution
  Future<_SyncDetailResult> _syncAssets() async {
    int synced = 0;
    int conflicts = 0;

    // Download remote assets
    final remoteData = await _yandexDisk.downloadData('assets.json');
    
    if (remoteData != null) {
      final remoteAssets = (remoteData['assets'] as List? ?? [])
          .map((e) => Asset.fromJson(e as Map<String, dynamic>))
          .toList();

      final localAssets = _assetsBox?.values.toList() ?? [];

      // Create maps for easier lookup
      final remoteMap = {for (var a in remoteAssets) a.id: a};
      final localMap = {for (var a in localAssets) a.id: a};

      // Merge with conflict resolution
      final mergedAssets = <String, Asset>{};

      // Process all unique IDs
      final allIds = {...remoteMap.keys, ...localMap.keys};

      for (final id in allIds) {
        final remote = remoteMap[id];
        final local = localMap[id];

        if (remote != null && local != null) {
          // Conflict - use newer version
          if (remote.updatedAt.isAfter(local.updatedAt)) {
            mergedAssets[id] = remote;
            conflicts++;
          } else {
            mergedAssets[id] = local;
          }
        } else if (remote != null) {
          // Only remote exists
          mergedAssets[id] = remote;
          synced++;
        } else if (local != null) {
          // Only local exists
          mergedAssets[id] = local;
          synced++;
        }
      }

      // Save merged assets locally
      await _assetsBox?.clear();
      for (final asset in mergedAssets.values) {
        await _assetsBox?.put(asset.id, asset);
      }

      // Upload merged assets
      await _uploadAssets();
    } else {
      // No remote data - upload local only
      await _uploadAssets();
      synced = _assetsBox?.length ?? 0;
    }

    return _SyncDetailResult(synced: synced, conflicts: conflicts);
  }

  /// Upload local assets to Yandex.Disk
  Future<bool> _uploadAssets() async {
    final assets = _assetsBox?.values.toList() ?? [];
    final data = {
      'version': 1,
      'lastModified': DateTime.now().toIso8601String(),
      'assets': assets.map((a) => a.toJson()).toList(),
    };
    return await _yandexDisk.uploadData('assets.json', data);
  }

  /// Sync exchange rates
  Future<void> _syncExchangeRates() async {
    final localRates = _ratesBox?.values.toList() ?? [];
    
    final data = {
      'version': 1,
      'lastModified': DateTime.now().toIso8601String(),
      'rates': localRates.map((r) => r.toJson()).toList(),
    };
    
    await _yandexDisk.uploadData('exchange_rates.json', data);
  }

  /// Sync settings
  Future<void> _syncSettings() async {
    final settings = _settingsBox?.get('main') ?? AppSettings.withDefaults();
    
    final data = {
      'version': 1,
      'lastModified': DateTime.now().toIso8601String(),
      'settings': settings.toJson(),
    };
    
    await _yandexDisk.uploadData('settings.json', data);
  }

  /// Update last sync time
  Future<void> _updateLastSyncTime() async {
    final settings = _settingsBox?.get('main') ?? AppSettings.withDefaults();
    final updated = settings.copyWith(lastSync: DateTime.now());
    await _settingsBox?.put('main', updated);
  }

  /// Force upload all local data (for initial sync)
  Future<bool> forceUpload() async {
    try {
      await _uploadAssets();
      await _syncExchangeRates();
      await _syncSettings();
      await _updateLastSyncTime();
      return true;
    } catch (e) {
      debugPrint('Force upload error: $e');
      return false;
    }
  }

  /// Force download and overwrite local data
  Future<bool> forceDownload() async {
    try {
      // Download assets
      final assetsData = await _yandexDisk.downloadData('assets.json');
      if (assetsData != null) {
        final assets = (assetsData['assets'] as List)
            .map((e) => Asset.fromJson(e as Map<String, dynamic>));
        await _assetsBox?.clear();
        for (final asset in assets) {
          await _assetsBox?.put(asset.id, asset);
        }
      }

      // Download settings
      final settingsData = await _yandexDisk.downloadData('settings.json');
      if (settingsData != null) {
        final settings = AppSettings.fromJson(settingsData['settings']);
        await _settingsBox?.put('main', settings);
      }

      await _updateLastSyncTime();
      return true;
    } catch (e) {
      debugPrint('Force download error: $e');
      return false;
    }
  }

  // Getters for local data
  List<Asset> get assets => _assetsBox?.values.toList() ?? [];
  List<ExchangeRate> get exchangeRates => _ratesBox?.values.toList() ?? [];
  AppSettings? get settings => _settingsBox?.get('main');
  DateTime? get lastSync => settings?.lastSync;

  // CRUD operations
  Future<void> addAsset(Asset asset) async {
    await _assetsBox?.put(asset.id, asset);
  }

  Future<void> updateAsset(Asset asset) async {
    await _assetsBox?.put(asset.id, asset.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> deleteAsset(String id) async {
    await _assetsBox?.delete(id);
  }

  Future<void> updateExchangeRate(ExchangeRate rate) async {
    await _ratesBox?.put(rate.id, rate);
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _settingsBox?.put('main', settings);
  }
}

/// Sync result
class SyncResult {
  final bool success;
  final String message;
  final int assetsSynced;
  final int? conflictsResolved;

  const SyncResult({
    required this.success,
    required this.message,
    required this.assetsSynced,
    this.conflictsResolved,
  });
}

/// Internal sync detail result
class _SyncDetailResult {
  final int synced;
  final int conflicts;

  const _SyncDetailResult({required this.synced, required this.conflicts});
}

/// Sync metadata for tracking
@HiveType(typeId: 10)
class SyncMetadata extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final DateTime lastSync;
  
  @HiveField(2)
  final String deviceId;

  SyncMetadata({
    required this.id,
    required this.lastSync,
    required this.deviceId,
  });
}
