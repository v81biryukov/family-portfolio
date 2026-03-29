// GENERATED CODE - DO NOT MODIFY BY HAND
// Hive Adapters for Settings Models

part of 'settings_model.dart';

// OwnerInfo Adapter
class OwnerInfoAdapter extends TypeAdapter<OwnerInfo> {
  @override
  final int typeId = 3;

  @override
  OwnerInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OwnerInfo(
      id: fields[0] as String,
      code: fields[1] as String,
      name: fields[2] as String,
      color: fields[3] as String,
      isDefault: fields[4] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, OwnerInfo obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OwnerInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// CurrencyInfo Adapter
class CurrencyInfoAdapter extends TypeAdapter<CurrencyInfo> {
  @override
  final int typeId = 4;

  @override
  CurrencyInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CurrencyInfo(
      id: fields[0] as String,
      code: fields[1] as String,
      name: fields[2] as String,
      symbol: fields[3] as String,
      flag: fields[4] as String,
      isDefault: fields[5] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CurrencyInfo obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.symbol)
      ..writeByte(4)
      ..write(obj.flag)
      ..writeByte(5)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// AssetTypeInfo Adapter
class AssetTypeInfoAdapter extends TypeAdapter<AssetTypeInfo> {
  @override
  final int typeId = 5;

  @override
  AssetTypeInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssetTypeInfo(
      id: fields[0] as String,
      name: fields[1] as String,
      color: fields[2] as String,
      isDefault: fields[3] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, AssetTypeInfo obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.color)
      ..writeByte(3)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetTypeInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// AppSettings Adapter
class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 6;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      baseCurrency: fields[0] as String? ?? 'USD',
      lastSync: fields[1] as DateTime?,
      owners: (fields[2] as List?)?.cast<OwnerInfo>() ?? [],
      currencies: (fields[3] as List?)?.cast<CurrencyInfo>() ?? [],
      assetTypes: (fields[4] as List?)?.cast<AssetTypeInfo>() ?? [],
      biometricEnabled: fields[5] as bool? ?? false,
      pinEnabled: fields[6] as bool? ?? false,
      encryptedPinHash: fields[7] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.baseCurrency)
      ..writeByte(1)
      ..write(obj.lastSync)
      ..writeByte(2)
      ..write(obj.owners)
      ..writeByte(3)
      ..write(obj.currencies)
      ..writeByte(4)
      ..write(obj.assetTypes)
      ..writeByte(5)
      ..write(obj.biometricEnabled)
      ..writeByte(6)
      ..write(obj.pinEnabled)
      ..writeByte(7)
      ..write(obj.encryptedPinHash);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// SyncMetadata Adapter
class SyncMetadataAdapter extends TypeAdapter<SyncMetadata> {
  @override
  final int typeId = 10;

  @override
  SyncMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncMetadata(
      id: fields[0] as String,
      lastSync: fields[1] as DateTime,
      deviceId: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SyncMetadata obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lastSync)
      ..writeByte(2)
      ..write(obj.deviceId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
