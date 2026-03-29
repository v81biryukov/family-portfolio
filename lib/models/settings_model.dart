import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 3)
class OwnerInfo extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String code;
  
  @HiveField(2)
  String name;
  
  @HiveField(3)
  String color;
  
  @HiveField(4)
  bool isDefault;

  OwnerInfo({
    required this.id,
    required this.code,
    required this.name,
    required this.color,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'color': color,
      'isDefault': isDefault,
    };
  }

  factory OwnerInfo.fromJson(Map<String, dynamic> json) {
    return OwnerInfo(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

@HiveType(typeId: 4)
class CurrencyInfo extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String code;
  
  @HiveField(2)
  String name;
  
  @HiveField(3)
  String symbol;
  
  @HiveField(4)
  String flag;
  
  @HiveField(5)
  bool isDefault;

  CurrencyInfo({
    required this.id,
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'symbol': symbol,
      'flag': flag,
      'isDefault': isDefault,
    };
  }

  factory CurrencyInfo.fromJson(Map<String, dynamic> json) {
    return CurrencyInfo(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      flag: json['flag'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

@HiveType(typeId: 5)
class AssetTypeInfo extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String color;
  
  @HiveField(3)
  bool isDefault;

  AssetTypeInfo({
    required this.id,
    required this.name,
    required this.color,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'isDefault': isDefault,
    };
  }

  factory AssetTypeInfo.fromJson(Map<String, dynamic> json) {
    return AssetTypeInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

@HiveType(typeId: 6)
class AppSettings extends HiveObject {
  @HiveField(0)
  String baseCurrency;
  
  @HiveField(1)
  DateTime? lastSync;
  
  @HiveField(2)
  List<OwnerInfo> owners;
  
  @HiveField(3)
  List<CurrencyInfo> currencies;
  
  @HiveField(4)
  List<AssetTypeInfo> assetTypes;
  
  @HiveField(5)
  bool biometricEnabled;
  
  @HiveField(6)
  bool pinEnabled;
  
  @HiveField(7)
  String encryptedPinHash;

  AppSettings({
    this.baseCurrency = 'USD',
    this.lastSync,
    this.owners = const [],
    this.currencies = const [],
    this.assetTypes = const [],
    this.biometricEnabled = false,
    this.pinEnabled = false,
    this.encryptedPinHash = '',
  });

  factory AppSettings.withDefaults() => AppSettings(
    owners: defaultOwners,
    currencies: defaultCurrencies,
    assetTypes: defaultAssetTypes,
  );

  Map<String, dynamic> toJson() {
    return {
      'baseCurrency': baseCurrency,
      'lastSync': lastSync?.toIso8601String(),
      'owners': owners.map((o) => o.toJson()).toList(),
      'currencies': currencies.map((c) => c.toJson()).toList(),
      'assetTypes': assetTypes.map((t) => t.toJson()).toList(),
      'biometricEnabled': biometricEnabled,
      'pinEnabled': pinEnabled,
      'encryptedPinHash': encryptedPinHash,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      baseCurrency: json['baseCurrency'] as String? ?? 'USD',
      lastSync: json['lastSync'] != null 
          ? DateTime.parse(json['lastSync'] as String) 
          : null,
      owners: (json['owners'] as List?)
              ?.map((e) => OwnerInfo.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      currencies: (json['currencies'] as List?)
              ?.map((e) => CurrencyInfo.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      assetTypes: (json['assetTypes'] as List?)
              ?.map((e) => AssetTypeInfo.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      pinEnabled: json['pinEnabled'] as bool? ?? false,
      encryptedPinHash: json['encryptedPinHash'] as String? ?? '',
    );
  }

  // Copy with method
  AppSettings copyWith({
    String? baseCurrency,
    DateTime? lastSync,
    List<OwnerInfo>? owners,
    List<CurrencyInfo>? currencies,
    List<AssetTypeInfo>? assetTypes,
    bool? biometricEnabled,
    bool? pinEnabled,
    String? encryptedPinHash,
  }) {
    return AppSettings(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      lastSync: lastSync ?? this.lastSync,
      owners: owners ?? this.owners,
      currencies: currencies ?? this.currencies,
      assetTypes: assetTypes ?? this.assetTypes,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      encryptedPinHash: encryptedPinHash ?? this.encryptedPinHash,
    );
  }
}

/// Sync metadata for tracking
@HiveType(typeId: 10)
class SyncMetadata extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  DateTime lastSync;
  
  @HiveField(2)
  String deviceId;

  SyncMetadata({
    required this.id,
    required this.lastSync,
    required this.deviceId,
  });
}

// Default values
final defaultOwners = [
  OwnerInfo(id: 'owner-v', code: 'V', name: 'V', color: '#3b82f6', isDefault: true),
  OwnerInfo(id: 'owner-m', code: 'M', name: 'M', color: '#ec4899', isDefault: true),
];

final defaultCurrencies = [
  CurrencyInfo(id: 'ccy-usd', code: 'USD', name: 'US Dollar', symbol: r'$', flag: '🇺🇸', isDefault: true),
  CurrencyInfo(id: 'ccy-eur', code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺', isDefault: true),
  CurrencyInfo(id: 'ccy-rub', code: 'RUB', name: 'Russian Ruble', symbol: '₽', flag: '🇷🇺', isDefault: true),
];

final defaultAssetTypes = [
  AssetTypeInfo(id: 'type-deposit', name: 'Bank Deposit', color: '#10b981', isDefault: true),
  AssetTypeInfo(id: 'type-cash', name: 'Cash', color: '#f59e0b', isDefault: true),
  AssetTypeInfo(id: 'type-corp-bonds', name: 'Corporate Bonds', color: '#8b5cf6', isDefault: true),
  AssetTypeInfo(id: 'type-life', name: 'Life Assurance', color: '#ec4899', isDefault: true),
  AssetTypeInfo(id: 'type-bonds', name: 'Bonds', color: '#06b6d4', isDefault: true),
  AssetTypeInfo(id: 'type-money-market', name: 'Money Market', color: '#3b82f6', isDefault: true),
  AssetTypeInfo(id: 'type-stocks', name: 'Stocks', color: '#ef4444', isDefault: true),
];

// Common countries
const commonCountries = [
  'Russia', 'US', 'UAE', 'KZ', 'UK', 'Germany', 'France',
  'Switzerland', 'Singapore', 'Hong Kong', 'China', 'Japan', 'Canada', 'Australia',
];

// Common institutions
const commonInstitutions = ['Bank 1', 'Bank 2', 'X Inc', 'Y Inc'];
